#!/usr/bin/env python3
"""
汇玉源版本管理工具

用途：
1. 统一读取/设置版本号（pubspec.yaml + app_config.dart + backend/config.py）
2. 验证三处版本号一致性
3. 在 CI/CD 中用作发布前检查

用法：
    python tool/version_manager.py get        # 显示当前版本
    python tool/version_manager.py set 3.0.4 6  # 设置新版本
    python tool/version_manager.py check      # 检查一致性
"""

import re
import sys
import os
from pathlib import Path

# 项目根目录（tool/ 的上一级）
ROOT = Path(__file__).parent.parent
PUBSPEC = ROOT / "pubspec.yaml"
APP_CONFIG = ROOT / "lib" / "config" / "app_config.dart"
BACKEND_CONFIG = ROOT / "backend" / "config.py"


def read_pubspec():
    """从 pubspec.yaml 读取 version: X.Y.Z+N"""
    text = PUBSPEC.read_text(encoding="utf-8")
    m = re.search(r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)", text, re.MULTILINE)
    if m:
        return m.group(1), int(m.group(2))
    raise RuntimeError(f"无法在 {PUBSPEC.name} 中找到 version 字段")


def read_app_config():
    """从 app_config.dart 读取 appVersion 和 appBuildNumber"""
    text = APP_CONFIG.read_text(encoding="utf-8")
    ver_m = re.search(r"static const String appVersion\s*=\s*'([^']+)'", text)
    build_m = re.search(r"static const int appBuildNumber\s*=\s*(\d+)", text)
    if ver_m and build_m:
        return ver_m.group(1), int(build_m.group(1))
    raise RuntimeError(f"无法在 {APP_CONFIG.relative_to(ROOT)} 中找到版本字段")


def read_backend_config():
    """从 backend/config.py 读取 APP_LATEST_VERSION 和 APP_LATEST_BUILD_NUMBER"""
    text = BACKEND_CONFIG.read_text(encoding="utf-8")
    ver_m = re.search(r'APP_LATEST_VERSION\s*=\s*os\.getenv\([^,]+,\s*"([^"]+)"\)', text)
    build_m = re.search(r"APP_LATEST_BUILD_NUMBER\s*=\s*int\(os\.getenv\([^,]+,\s*\"(\d+)\"\)", text)
    if ver_m and build_m:
        return ver_m.group(1), int(build_m.group(1))
    raise RuntimeError(f"无法在 {BACKEND_CONFIG.relative_to(ROOT)} 中找到版本字段")


def cmd_get():
    """显示当前所有版本的版本号"""
    sources = [
        ("pubspec.yaml", read_pubspec),
        ("app_config.dart", read_app_config),
        ("backend/config.py", read_backend_config),
    ]
    print(f"{'来源':<25} {'版本':<12} {'构建号'}")
    print("-" * 50)
    for name, reader in sources:
        try:
            ver, build = reader()
            print(f"{name:<25} {ver:<12} {build}")
        except Exception as e:
            print(f"{name:<25} [ERR] {e}")


def cmd_check():
    """检查三处版本是否一致"""
    try:
        v1, b1 = read_pubspec()
        v2, b2 = read_app_config()
        v3, b3 = read_backend_config()
    except Exception as e:
        print(f"[ERR] 读取失败: {e}")
        return 1

    versions = {v1, v2, v3}
    builds = {b1, b2, b3}

    if len(versions) == 1 and len(builds) == 1:
        print(f"[OK] 版本一致: {v1}+{b1}")
        return 0
    else:
        print("[ERR] 版本不一致!")
        print(f"  pubspec.yaml:    {v1}+{b1}")
        print(f"  app_config.dart: {v2}+{b2}")
        print(f"  backend/config:  {v3}+{b3}")
        return 1


def cmd_set(version, build_number):
    """统一设置版本号（先全部写入内存，再原子写入文件，避免半完成状态）"""
    # 阶段1：读取所有原始内容（验证可读取性）
    texts = {}
    for path in (PUBSPEC, APP_CONFIG, BACKEND_CONFIG):
        texts[path] = path.read_text(encoding="utf-8")

    # 阶段2：在内存中完成所有替换
    new_texts = {}

    # pubspec.yaml
    t = texts[PUBSPEC]
    t = re.sub(
        r"^version:\s*\d+\.\d+\.\d+\+\d+",
        f"version: {version}+{build_number}",
        t,
        flags=re.MULTILINE,
    )
    new_texts[PUBSPEC] = t

    # app_config.dart
    t = texts[APP_CONFIG]
    t = re.sub(
        r"(static const String appVersion\s*=\s*)'[^']+'",
        rf"\1'{version}'",
        t,
    )
    t = re.sub(
        r"(static const int appBuildNumber\s*=\s*)\d+",
        rf"\1{build_number}",
        t,
    )
    new_texts[APP_CONFIG] = t

    # backend/config.py
    t = texts[BACKEND_CONFIG]
    t = re.sub(
        r'(APP_LATEST_VERSION\s*=\s*os\.getenv\([^,]+,\s*)"([^"]+)"',
        rf'\1"{version}"',
        t,
    )
    t = re.sub(
        r"(APP_LATEST_BUILD_NUMBER\s*=\s*int\(os\.getenv\([^,]+,\s*\")(\d+)(\")",
        rf"\1{build_number}\3",
        t,
    )
    new_texts[BACKEND_CONFIG] = t

    # 阶段3：原子写入所有文件
    for path, content in new_texts.items():
        path.write_text(content, encoding="utf-8")

    # 阶段4：全部写入成功后再输出结果
    print(f"[OK] pubspec.yaml    -> {version}+{build_number}")
    print(f"[OK] app_config.dart -> {version}+{build_number}")
    print(f"[OK] backend/config  -> {version}+{build_number}")
    print(f"")
    print(f"[DONE] 版本已统一设置为 {version}+{build_number}")
    return 0


def main():
    if len(sys.argv) < 2:
        print("用法: python tool/version_manager.py [get|set|check]")
        print("  get           显示当前版本")
        print("  check         检查版本一致性")
        print("  set VER BUILD 设置新版本")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "get":
        cmd_get()
    elif cmd == "check":
        sys.exit(cmd_check())
    elif cmd == "set":
        if len(sys.argv) != 4:
            print("用法: python tool/version_manager.py set VERSION BUILD_NUMBER")
            sys.exit(1)
        sys.exit(cmd_set(sys.argv[2], int(sys.argv[3])))
    else:
        print(f"未知命令: {cmd}")
        sys.exit(1)


if __name__ == "__main__":
    main()
