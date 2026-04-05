import os
import codecs
import re

def fix_profile():
    p = 'lib/screens/profile/profile_screen.dart'
    with codecs.open(p, 'r', 'utf-8') as f:
        c = f.read()
    
    # fix buildUserCard call
    c = c.replace('_buildUserCard(context, username, isAdmin)', '_buildUserCard(context, ref, username, isAdmin)')
    # fix menuItem call
    c = c.replace('_buildMenuItem(', '_buildMenuItem(ref, ')
    # fix buildOrderSection call
    c = c.replace('_buildOrderSection(context)', '_buildOrderSection(context, ref)')
    # fix buildToolsSection call
    c = c.replace('_buildToolsSection(context)', '_buildToolsSection(context, ref)')
    
    # fix signatures if not already fixed
    c = re.sub(r'Widget\s+_buildUserCard\(BuildContext\s+context,\s*String\s+username,\s*bool\s+isAdmin\)', 'Widget _buildUserCard(BuildContext context, WidgetRef ref, String username, bool isAdmin)', c)
    c = re.sub(r'Widget\s+_buildMenuItem\(\{', 'Widget _buildMenuItem(WidgetRef ref, {', c)
    c = re.sub(r'Widget\s+_buildOrderSection\(BuildContext\s+context\)', 'Widget _buildOrderSection(BuildContext context, WidgetRef ref)', c)
    c = re.sub(r'Widget\s+_buildToolsSection\(BuildContext\s+context\)', 'Widget _buildToolsSection(BuildContext context, WidgetRef ref)', c)
    
    # fix duplicate definition (e.g. Widget _buildSomething(BuildContext context, WidgetRef ref) having another ref inside)
    # let's just use regex to remove WidgetRef ref where it's already there and we accidentally added a second one
    c = c.replace('Widget _buildMenuItem(WidgetRef ref, WidgetRef ref, {', 'Widget _buildMenuItem(WidgetRef ref, {')
    c = c.replace('_buildMenuItem(ref, ref,', '_buildMenuItem(ref,')

    # other undefined refs
    # line 377: _buildOrderItem(context, '待付款', Icons.account_balance_wallet_outlined) => needs ref
    c = c.replace("_buildOrderItem(context, ref.tr('order_pending_payment')", "_buildOrderItem(context, ref, ref.tr('order_pending_payment')")
    c = c.replace("_buildOrderItem(context, ref.tr('order_pending_shipment')", "_buildOrderItem(context, ref, ref.tr('order_pending_shipment')")
    c = c.replace("_buildOrderItem(context, ref.tr('order_pending_receipt')", "_buildOrderItem(context, ref, ref.tr('order_pending_receipt')")
    c = c.replace("_buildOrderItem(context, ref.tr('order_return')", "_buildOrderItem(context, ref, ref.tr('order_return')")
    c = re.sub(r'Widget\s+_buildOrderItem\(BuildContext\s+context,\s*String\s+title,\s*IconData\s+icon\)', 'Widget _buildOrderItem(BuildContext context, WidgetRef ref, String title, IconData icon)', c)

    # 1059, 1084, 1092, etc. might be _showPrivacyPolicy, _showUserAgreement etc.
    c = c.replace("void _showPrivacyPolicy(BuildContext context)", "void _showPrivacyPolicy(BuildContext context, WidgetRef ref)")
    c = c.replace("_showPrivacyPolicy(context)", "_showPrivacyPolicy(context, ref)")
    c = c.replace("void _showUserAgreement(BuildContext context)", "void _showUserAgreement(BuildContext context, WidgetRef ref)")
    c = c.replace("_showUserAgreement(context)", "_showUserAgreement(context, ref)")
    c = c.replace("void _showAboutDialog(BuildContext context)", "void _showAboutDialog(BuildContext context, WidgetRef ref)")
    c = c.replace("_showAboutDialog(context)", "_showAboutDialog(context, ref)")
    c = c.replace("void _showFeatureNotReady(BuildContext context, String feature)", "void _showFeatureNotReady(BuildContext context, WidgetRef ref, String feature)")
    c = c.replace("_showFeatureNotReady(context,", "_showFeatureNotReady(context, ref,")

    # fix duplicate refs again
    c = c.replace('_showFeatureNotReady(context, ref, ref,', '_showFeatureNotReady(context, ref,')

    with codecs.open(p, 'w', 'utf-8') as f:
        f.write(c)

def fix_empty_state():
    p = 'lib/widgets/common/empty_state.dart'
    with codecs.open(p, 'r', 'utf-8') as f:
        c = f.read()
    c = c.replace('_getConfig()', '_getConfig(WidgetRef ref)')
    c = c.replace('final config = _getConfig(WidgetRef ref);', 'final config = _getConfig(ref);')
    with codecs.open(p, 'w', 'utf-8') as f:
        f.write(c)

def fix_promotional_banner():
    p = 'lib/widgets/promotional_banner.dart'
    with codecs.open(p, 'r', 'utf-8') as f:
        c = f.read()
    
    # move _banners inside state class
    list_str = "List<_BannerData> get _banners => ["
    if list_str in c and "class _PromotionalBannerState" in c:
        # extract it
        parts = c.split(list_str)
        if len(parts) > 1:
            top_part = parts[0]
            rest = parts[1]
            end_idx = rest.find('];')
            if end_idx != -1:
                arr_content = rest[:end_idx+2]
                bottom_part = rest[end_idx+2:]
                
                # put it inside state class
                state_cls = "class _PromotionalBannerState extends ConsumerState<PromotionalBanner> {"
                if state_cls in bottom_part:
                    bottom_part = bottom_part.replace(state_cls, state_cls + "\n\n  " + list_str + arr_content)
                    c = top_part + bottom_part
        with codecs.open(p, 'w', 'utf-8') as f:
            f.write(c)

fix_profile()
fix_empty_state()
fix_promotional_banner()
print("Done fixing everything!")
