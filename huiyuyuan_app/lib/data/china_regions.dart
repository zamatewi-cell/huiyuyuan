// China administrative region data - province/city/district picker
// Uses Unicode escapes to avoid encoding issues
// ignore_for_file: constant_identifier_names
library;

class ChinaRegions {
  ChinaRegions._();

  /// Get all province names (display names)
  static List<String> get provinces => _provinces.toList();

  /// Get cities for a given province
  static List<String> getCities(String province) {
    final idx = _provinces.indexOf(province);
    if (idx < 0) return [];
    return _citiesByProvince[idx];
  }

  /// Get districts for a given province + city
  static List<String> getDistricts(String province, String city) {
    final key = '$province|$city';
    return _districtMap[key] ?? [];
  }

  // 34 province-level divisions
  static final List<String> _provinces = [
    '\u5317\u4EAC\u5E02', // Beijing
    '\u5929\u6D25\u5E02', // Tianjin
    '\u6CB3\u5317\u7701', // Hebei
    '\u5C71\u897F\u7701', // Shanxi
    '\u5185\u8499\u53E4\u81EA\u6CBB\u533A', // Inner Mongolia
    '\u8FBD\u5B81\u7701', // Liaoning
    '\u5409\u6797\u7701', // Jilin
    '\u9ED1\u9F99\u6C5F\u7701', // Heilongjiang
    '\u4E0A\u6D77\u5E02', // Shanghai
    '\u6C5F\u82CF\u7701', // Jiangsu
    '\u6D59\u6C5F\u7701', // Zhejiang
    '\u5B89\u5FBD\u7701', // Anhui
    '\u798F\u5EFA\u7701', // Fujian
    '\u6C5F\u897F\u7701', // Jiangxi
    '\u5C71\u4E1C\u7701', // Shandong
    '\u6CB3\u5357\u7701', // Henan
    '\u6E56\u5317\u7701', // Hubei
    '\u6E56\u5357\u7701', // Hunan
    '\u5E7F\u4E1C\u7701', // Guangdong
    '\u5E7F\u897F\u58EE\u65CF\u81EA\u6CBB\u533A', // Guangxi
    '\u6D77\u5357\u7701', // Hainan
    '\u91CD\u5E86\u5E02', // Chongqing
    '\u56DB\u5DDD\u7701', // Sichuan
    '\u8D35\u5DDE\u7701', // Guizhou
    '\u4E91\u5357\u7701', // Yunnan
    '\u897F\u85CF\u81EA\u6CBB\u533A', // Tibet
    '\u9655\u897F\u7701', // Shaanxi
    '\u7518\u8083\u7701', // Gansu
    '\u9752\u6D77\u7701', // Qinghai
    '\u5B81\u590F\u56DE\u65CF\u81EA\u6CBB\u533A', // Ningxia
    '\u65B0\u7586\u7EF4\u543E\u5C14\u81EA\u6CBB\u533A', // Xinjiang
    '\u9999\u6E2F\u7279\u522B\u884C\u653F\u533A', // Hong Kong
    '\u6FB3\u95E8\u7279\u522B\u884C\u653F\u533A', // Macao
    '\u53F0\u6E7E\u7701', // Taiwan
  ];

  // Cities indexed by province index
  static final List<List<String>> _citiesByProvince = [
    // 0: Beijing
    ['\u5317\u4EAC\u5E02'],
    // 1: Tianjin
    ['\u5929\u6D25\u5E02'],
    // 2: Hebei
    [
      '\u77F3\u5BB6\u5E84\u5E02',
      '\u5510\u5C71\u5E02',
      '\u79E6\u7687\u5C9B\u5E02',
      '\u90AF\u90F8\u5E02',
      '\u90A2\u53F0\u5E02',
      '\u4FDD\u5B9A\u5E02',
      '\u5F20\u5BB6\u53E3\u5E02',
      '\u627F\u5FB7\u5E02',
      '\u6CA7\u5DDE\u5E02',
      '\u5ECA\u574A\u5E02',
      '\u8861\u6C34\u5E02'
    ],
    // 3: Shanxi
    [
      '\u592A\u539F\u5E02',
      '\u5927\u540C\u5E02',
      '\u9633\u6CC9\u5E02',
      '\u957F\u6CBB\u5E02',
      '\u664B\u57CE\u5E02',
      '\u6714\u5DDE\u5E02',
      '\u664B\u4E2D\u5E02',
      '\u8FD0\u57CE\u5E02',
      '\u5FFB\u5DDE\u5E02',
      '\u4E34\u6C7E\u5E02',
      '\u5415\u6881\u5E02'
    ],
    // 4: Inner Mongolia
    [
      '\u547C\u548C\u6D69\u7279\u5E02',
      '\u5305\u5934\u5E02',
      '\u4E4C\u6D77\u5E02',
      '\u8D64\u5CF0\u5E02',
      '\u901A\u8FBD\u5E02',
      '\u9102\u5C14\u591A\u65AF\u5E02',
      '\u547C\u4F26\u8D1D\u5C14\u5E02',
      '\u5DF4\u5F66\u6DD6\u5C14\u5E02',
      '\u4E4C\u5170\u5BDF\u5E03\u5E02',
      '\u9521\u6797\u90ED\u52D2\u76DF',
      '\u963F\u62C9\u5584\u76DF'
    ],
    // 5: Liaoning
    [
      '\u6C88\u9633\u5E02',
      '\u5927\u8FDE\u5E02',
      '\u978D\u5C71\u5E02',
      '\u629A\u987A\u5E02',
      '\u672C\u6EAA\u5E02',
      '\u4E39\u4E1C\u5E02',
      '\u9526\u5DDE\u5E02',
      '\u8425\u53E3\u5E02',
      '\u961C\u65B0\u5E02',
      '\u8FBD\u9633\u5E02',
      '\u76D8\u9526\u5E02',
      '\u94C1\u5CED\u5E02',
      '\u671D\u9633\u5E02',
      '\u846B\u82A6\u5C9B\u5E02'
    ],
    // 6: Jilin
    [
      '\u957F\u6625\u5E02',
      '\u5409\u6797\u5E02',
      '\u56DB\u5E73\u5E02',
      '\u8FBD\u6E90\u5E02',
      '\u901A\u5316\u5E02',
      '\u767D\u5C71\u5E02',
      '\u677E\u539F\u5E02',
      '\u767D\u57CE\u5E02',
      '\u5EF6\u8FB9\u671D\u9C9C\u65CF\u81EA\u6CBB\u5DDE'
    ],
    // 7: Heilongjiang
    [
      '\u54C8\u5C14\u6EE8\u5E02',
      '\u9F50\u9F50\u54C8\u5C14\u5E02',
      '\u9E21\u897F\u5E02',
      '\u9E64\u5C97\u5E02',
      '\u53CC\u9E2D\u5C71\u5E02',
      '\u5927\u5E86\u5E02',
      '\u4F0A\u6625\u5E02',
      '\u4F73\u6728\u65AF\u5E02',
      '\u4E03\u53F0\u6CB3\u5E02',
      '\u7261\u4E39\u6C5F\u5E02',
      '\u9ED1\u6CB3\u5E02',
      '\u7EE5\u5316\u5E02',
      '\u5927\u5174\u5B89\u5CAD\u5730\u533A'
    ],
    // 8: Shanghai
    ['\u4E0A\u6D77\u5E02'],
    // 9: Jiangsu
    [
      '\u5357\u4EAC\u5E02',
      '\u65E0\u9521\u5E02',
      '\u5F90\u5DDE\u5E02',
      '\u5E38\u5DDE\u5E02',
      '\u82CF\u5DDE\u5E02',
      '\u5357\u901A\u5E02',
      '\u8FDE\u4E91\u6E2F\u5E02',
      '\u6DEE\u5B89\u5E02',
      '\u76D0\u57CE\u5E02',
      '\u626C\u5DDE\u5E02',
      '\u9547\u6C5F\u5E02',
      '\u6CF0\u5DDE\u5E02',
      '\u5BBF\u8FC1\u5E02'
    ],
    // 10: Zhejiang
    [
      '\u676D\u5DDE\u5E02',
      '\u5B81\u6CE2\u5E02',
      '\u6E29\u5DDE\u5E02',
      '\u5609\u5174\u5E02',
      '\u6E56\u5DDE\u5E02',
      '\u7ECD\u5174\u5E02',
      '\u91D1\u534E\u5E02',
      '\u8862\u5DDE\u5E02',
      '\u821F\u5C71\u5E02',
      '\u53F0\u5DDE\u5E02',
      '\u4E3D\u6C34\u5E02'
    ],
    // 11: Anhui
    [
      '\u5408\u80A5\u5E02',
      '\u829C\u6E56\u5E02',
      '\u868C\u57E0\u5E02',
      '\u6DEE\u5357\u5E02',
      '\u9A6C\u978D\u5C71\u5E02',
      '\u6DEE\u5317\u5E02',
      '\u94DC\u9675\u5E02',
      '\u5B89\u5E86\u5E02',
      '\u9EC4\u5C71\u5E02',
      '\u6EC1\u5DDE\u5E02',
      '\u961C\u9633\u5E02',
      '\u5BBF\u5DDE\u5E02',
      '\u516D\u5B89\u5E02',
      '\u4EB3\u5DDE\u5E02',
      '\u6C60\u5DDE\u5E02',
      '\u5BA3\u57CE\u5E02'
    ],
    // 12: Fujian
    [
      '\u798F\u5DDE\u5E02',
      '\u53A6\u95E8\u5E02',
      '\u8386\u7530\u5E02',
      '\u4E09\u660E\u5E02',
      '\u6CC9\u5DDE\u5E02',
      '\u6F33\u5DDE\u5E02',
      '\u5357\u5E73\u5E02',
      '\u9F99\u5CA9\u5E02',
      '\u5B81\u5FB7\u5E02'
    ],
    // 13: Jiangxi
    [
      '\u5357\u660C\u5E02',
      '\u666F\u5FB7\u9547\u5E02',
      '\u840D\u4E61\u5E02',
      '\u4E5D\u6C5F\u5E02',
      '\u65B0\u4F59\u5E02',
      '\u9E70\u6F6D\u5E02',
      '\u8D63\u5DDE\u5E02',
      '\u5409\u5B89\u5E02',
      '\u5B9C\u6625\u5E02',
      '\u629A\u5DDE\u5E02',
      '\u4E0A\u9976\u5E02'
    ],
    // 14: Shandong
    [
      '\u6D4E\u5357\u5E02',
      '\u9752\u5C9B\u5E02',
      '\u6DC4\u535A\u5E02',
      '\u67A3\u5E84\u5E02',
      '\u4E1C\u8425\u5E02',
      '\u70DF\u53F0\u5E02',
      '\u6F4D\u574A\u5E02',
      '\u6D4E\u5B81\u5E02',
      '\u6CF0\u5B89\u5E02',
      '\u5A01\u6D77\u5E02',
      '\u65E5\u7167\u5E02',
      '\u6EE8\u5DDE\u5E02',
      '\u5FB7\u5DDE\u5E02',
      '\u804A\u57CE\u5E02',
      '\u4E34\u6C82\u5E02',
      '\u83CF\u6CFD\u5E02'
    ],
    // 15: Henan
    [
      '\u90D1\u5DDE\u5E02',
      '\u5F00\u5C01\u5E02',
      '\u6D1B\u9633\u5E02',
      '\u5E73\u9876\u5C71\u5E02',
      '\u5B89\u9633\u5E02',
      '\u9E64\u58C1\u5E02',
      '\u65B0\u4E61\u5E02',
      '\u7126\u4F5C\u5E02',
      '\u6FEE\u9633\u5E02',
      '\u8BB8\u660C\u5E02',
      '\u6F2F\u6CB3\u5E02',
      '\u4E09\u95E8\u5CE1\u5E02',
      '\u5357\u9633\u5E02',
      '\u5546\u4E18\u5E02',
      '\u4FE1\u9633\u5E02',
      '\u5468\u53E3\u5E02',
      '\u9A7B\u9A6C\u5E97\u5E02',
      '\u6D4E\u6E90\u5E02'
    ],
    // 16: Hubei
    [
      '\u6B66\u6C49\u5E02',
      '\u9EC4\u77F3\u5E02',
      '\u5341\u5830\u5E02',
      '\u5B9C\u660C\u5E02',
      '\u8944\u9633\u5E02',
      '\u9102\u5DDE\u5E02',
      '\u8346\u95E8\u5E02',
      '\u5B5D\u611F\u5E02',
      '\u8346\u5DDE\u5E02',
      '\u9EC4\u5188\u5E02',
      '\u54B8\u5B81\u5E02',
      '\u968F\u5DDE\u5E02',
      '\u6069\u65BD\u571F\u5BB6\u65CF\u82D7\u65CF\u81EA\u6CBB\u5DDE',
      '\u4ED9\u6843\u5E02',
      '\u6F5C\u6C5F\u5E02',
      '\u5929\u95E8\u5E02',
      '\u795E\u519C\u67B6\u6797\u533A'
    ],
    // 17: Hunan
    [
      '\u957F\u6C99\u5E02',
      '\u682A\u6D32\u5E02',
      '\u6E58\u6F6D\u5E02',
      '\u8861\u9633\u5E02',
      '\u90B5\u9633\u5E02',
      '\u5CB3\u9633\u5E02',
      '\u5E38\u5FB7\u5E02',
      '\u5F20\u5BB6\u754C\u5E02',
      '\u76CA\u9633\u5E02',
      '\u90F4\u5DDE\u5E02',
      '\u6C38\u5DDE\u5E02',
      '\u6000\u5316\u5E02',
      '\u5A04\u5E95\u5E02',
      '\u6E58\u897F\u571F\u5BB6\u65CF\u82D7\u65CF\u81EA\u6CBB\u5DDE'
    ],
    // 18: Guangdong
    [
      '\u5E7F\u5DDE\u5E02',
      '\u6DF1\u5733\u5E02',
      '\u73E0\u6D77\u5E02',
      '\u6C55\u5934\u5E02',
      '\u4F5B\u5C71\u5E02',
      '\u97F6\u5173\u5E02',
      '\u6E5B\u6C5F\u5E02',
      '\u8087\u5E86\u5E02',
      '\u6C5F\u95E8\u5E02',
      '\u8302\u540D\u5E02',
      '\u60E0\u5DDE\u5E02',
      '\u6885\u5DDE\u5E02',
      '\u6C55\u5C3E\u5E02',
      '\u6CB3\u6E90\u5E02',
      '\u9633\u6C5F\u5E02',
      '\u6E05\u8FDC\u5E02',
      '\u4E1C\u839E\u5E02',
      '\u4E2D\u5C71\u5E02',
      '\u6F6E\u5DDE\u5E02',
      '\u63ED\u9633\u5E02',
      '\u4E91\u6D6E\u5E02'
    ],
    // 19: Guangxi
    [
      '\u5357\u5B81\u5E02',
      '\u67F3\u5DDE\u5E02',
      '\u6842\u6797\u5E02',
      '\u68A7\u5DDE\u5E02',
      '\u5317\u6D77\u5E02',
      '\u9632\u57CE\u6E2F\u5E02',
      '\u94A6\u5DDE\u5E02',
      '\u8D35\u6E2F\u5E02',
      '\u7389\u6797\u5E02',
      '\u767E\u8272\u5E02',
      '\u8D3A\u5DDE\u5E02',
      '\u6CB3\u6C60\u5E02',
      '\u6765\u5BBE\u5E02',
      '\u5D07\u5DE6\u5E02'
    ],
    // 20: Hainan
    [
      '\u6D77\u53E3\u5E02',
      '\u4E09\u4E9A\u5E02',
      '\u4E09\u6C99\u5E02',
      '\u510B\u5DDE\u5E02',
      '\u4E94\u6307\u5C71\u5E02',
      '\u743C\u6D77\u5E02',
      '\u6587\u660C\u5E02',
      '\u4E07\u5B81\u5E02',
      '\u4E1C\u65B9\u5E02',
      '\u5B9A\u5B89\u53BF',
      '\u5C6F\u660C\u53BF',
      '\u6F84\u8FC8\u53BF',
      '\u4E34\u9AD8\u53BF',
      '\u767D\u6C99\u9ECE\u65CF\u81EA\u6CBB\u53BF',
      '\u660C\u6C5F\u9ECE\u65CF\u81EA\u6CBB\u53BF',
      '\u4E50\u4E1C\u9ECE\u65CF\u81EA\u6CBB\u53BF',
      '\u9675\u6C34\u9ECE\u65CF\u81EA\u6CBB\u53BF',
      '\u4FDD\u4EAD\u9ECE\u65CF\u82D7\u65CF\u81EA\u6CBB\u53BF',
      '\u743C\u4E2D\u9ECE\u65CF\u82D7\u65CF\u81EA\u6CBB\u53BF'
    ],
    // 21: Chongqing
    ['\u91CD\u5E86\u5E02'],
    // 22: Sichuan
    [
      '\u6210\u90FD\u5E02',
      '\u81EA\u8D21\u5E02',
      '\u6500\u679D\u82B1\u5E02',
      '\u6CF8\u5DDE\u5E02',
      '\u5FB7\u9633\u5E02',
      '\u7EF5\u9633\u5E02',
      '\u5E7F\u5143\u5E02',
      '\u9042\u5B81\u5E02',
      '\u5185\u6C5F\u5E02',
      '\u4E50\u5C71\u5E02',
      '\u5357\u5145\u5E02',
      '\u7709\u5C71\u5E02',
      '\u5B9C\u5BBE\u5E02',
      '\u5E7F\u5B89\u5E02',
      '\u8FBE\u5DDE\u5E02',
      '\u96C5\u5B89\u5E02',
      '\u5DF4\u4E2D\u5E02',
      '\u8D44\u9633\u5E02',
      '\u963F\u575D\u85CF\u65CF\u7F8C\u65CF\u81EA\u6CBB\u5DDE',
      '\u7518\u5B5C\u85CF\u65CF\u81EA\u6CBB\u5DDE',
      '\u51C9\u5C71\u5F5D\u65CF\u81EA\u6CBB\u5DDE'
    ],
    // 23: Guizhou
    [
      '\u8D35\u9633\u5E02',
      '\u516D\u76D8\u6C34\u5E02',
      '\u9075\u4E49\u5E02',
      '\u5B89\u987A\u5E02',
      '\u6BD5\u8282\u5E02',
      '\u94DC\u4EC1\u5E02',
      '\u9ED4\u897F\u5357\u5E03\u4F9D\u65CF\u82D7\u65CF\u81EA\u6CBB\u5DDE',
      '\u9ED4\u4E1C\u5357\u82D7\u65CF\u4F97\u65CF\u81EA\u6CBB\u5DDE',
      '\u9ED4\u5357\u5E03\u4F9D\u65CF\u82D7\u65CF\u81EA\u6CBB\u5DDE'
    ],
    // 24: Yunnan
    [
      '\u6606\u660E\u5E02',
      '\u66F2\u9756\u5E02',
      '\u7389\u6EAA\u5E02',
      '\u4FDD\u5C71\u5E02',
      '\u662D\u901A\u5E02',
      '\u4E3D\u6C5F\u5E02',
      '\u666E\u6D31\u5E02',
      '\u4E34\u6CA7\u5E02',
      '\u695A\u96C4\u5F5D\u65CF\u81EA\u6CBB\u5DDE',
      '\u7EA2\u6CB3\u54C8\u5C3C\u65CF\u5F5D\u65CF\u81EA\u6CBB\u5DDE',
      '\u6587\u5C71\u58EE\u65CF\u82D7\u65CF\u81EA\u6CBB\u5DDE',
      '\u897F\u53CC\u7248\u7EB3\u50A3\u65CF\u81EA\u6CBB\u5DDE',
      '\u5927\u7406\u767D\u65CF\u81EA\u6CBB\u5DDE',
      '\u5FB7\u5B8F\u50A3\u65CF\u666F\u9887\u65CF\u81EA\u6CBB\u5DDE',
      '\u6012\u6C5F\u5088\u50F3\u65CF\u81EA\u6CBB\u5DDE',
      '\u8FEA\u5E86\u85CF\u65CF\u81EA\u6CBB\u5DDE'
    ],
    // 25: Tibet
    [
      '\u62C9\u8428\u5E02',
      '\u65E5\u5580\u5219\u5E02',
      '\u660C\u90FD\u5E02',
      '\u6797\u829D\u5E02',
      '\u5C71\u5357\u5E02',
      '\u90A3\u66F2\u5E02',
      '\u963F\u91CC\u5730\u533A'
    ],
    // 26: Shaanxi
    [
      '\u897F\u5B89\u5E02',
      '\u94DC\u5DDD\u5E02',
      '\u5B9D\u9E21\u5E02',
      '\u54B8\u9633\u5E02',
      '\u6E2D\u5357\u5E02',
      '\u5EF6\u5B89\u5E02',
      '\u6C49\u4E2D\u5E02',
      '\u6986\u6797\u5E02',
      '\u5B89\u5EB7\u5E02',
      '\u5546\u6D1B\u5E02'
    ],
    // 27: Gansu
    [
      '\u5170\u5DDE\u5E02',
      '\u5609\u5CEA\u5173\u5E02',
      '\u91D1\u660C\u5E02',
      '\u767D\u94F6\u5E02',
      '\u5929\u6C34\u5E02',
      '\u6B66\u5A01\u5E02',
      '\u5F20\u6396\u5E02',
      '\u5E73\u51C9\u5E02',
      '\u9152\u6CC9\u5E02',
      '\u5E86\u9633\u5E02',
      '\u5B9A\u897F\u5E02',
      '\u9647\u5357\u5E02',
      '\u4E34\u590F\u56DE\u65CF\u81EA\u6CBB\u5DDE',
      '\u7518\u5357\u85CF\u65CF\u81EA\u6CBB\u5DDE'
    ],
    // 28: Qinghai
    [
      '\u897F\u5B81\u5E02',
      '\u6D77\u4E1C\u5E02',
      '\u6D77\u5317\u85CF\u65CF\u81EA\u6CBB\u5DDE',
      '\u9EC4\u5357\u85CF\u65CF\u81EA\u6CBB\u5DDE',
      '\u6D77\u5357\u85CF\u65CF\u81EA\u6CBB\u5DDE',
      '\u679C\u6D1B\u85CF\u65CF\u81EA\u6CBB\u5DDE',
      '\u7389\u6811\u85CF\u65CF\u81EA\u6CBB\u5DDE',
      '\u6D77\u897F\u8499\u53E4\u65CF\u85CF\u65CF\u81EA\u6CBB\u5DDE'
    ],
    // 29: Ningxia
    [
      '\u94F6\u5DDD\u5E02',
      '\u77F3\u5634\u5C71\u5E02',
      '\u5434\u5FE0\u5E02',
      '\u56FA\u539F\u5E02',
      '\u4E2D\u536B\u5E02'
    ],
    // 30: Xinjiang
    [
      '\u4E4C\u9C81\u6728\u9F50\u5E02',
      '\u514B\u62C9\u739B\u4F9D\u5E02',
      '\u5410\u9C81\u756A\u5E02',
      '\u54C8\u5BC6\u5E02',
      '\u660C\u5409\u56DE\u65CF\u81EA\u6CBB\u5DDE',
      '\u535A\u5C14\u5854\u62C9\u8499\u53E4\u81EA\u6CBB\u5DDE',
      '\u5DF4\u97F3\u90ED\u695E\u8499\u53E4\u81EA\u6CBB\u5DDE',
      '\u963F\u514B\u82CF\u5730\u533A',
      '\u5580\u4EC0\u5730\u533A',
      '\u548C\u7530\u5730\u533A',
      '\u4F0A\u7281\u54C8\u8428\u514B\u81EA\u6CBB\u5DDE',
      '\u5854\u57CE\u5730\u533A',
      '\u963F\u52D2\u6CF0\u5730\u533A'
    ],
    // 31: Hong Kong
    ['\u9999\u6E2F'],
    // 32: Macao
    ['\u6FB3\u95E8'],
    // 33: Taiwan
    [
      '\u53F0\u5317\u5E02',
      '\u65B0\u5317\u5E02',
      '\u6843\u56ED\u5E02',
      '\u53F0\u4E2D\u5E02',
      '\u53F0\u5357\u5E02',
      '\u9AD8\u96C4\u5E02',
      '\u57FA\u9686\u5E02',
      '\u65B0\u7AF9\u5E02',
      '\u5609\u4E49\u5E02',
      '\u82B1\u83B2\u53BF',
      '\u53F0\u4E1C\u53BF',
      '\u5B9C\u5170\u53BF',
      '\u6F8E\u6E56\u53BF',
      '\u91D1\u95E8\u53BF',
      '\u8FDE\u6C5F\u53BF'
    ],
  ];

  // District data keyed by "province|city"
  static final Map<String, List<String>> _districtMap = _buildDistrictMap();

  static Map<String, List<String>> _buildDistrictMap() {
    final m = <String, List<String>>{};
    // Helper to add districts
    void add(int pi, int ci, List<String> districts) {
      m['${_provinces[pi]}|${_citiesByProvince[pi][ci]}'] = districts;
    }

    // Beijing districts
    add(0, 0, [
      '\u4E1C\u57CE\u533A',
      '\u897F\u57CE\u533A',
      '\u671D\u9633\u533A',
      '\u4E30\u53F0\u533A',
      '\u77F3\u666F\u5C71\u533A',
      '\u6D77\u6DC0\u533A',
      '\u95E8\u5934\u6C9F\u533A',
      '\u623F\u5C71\u533A',
      '\u901A\u5DDE\u533A',
      '\u987A\u4E49\u533A',
      '\u660C\u5E73\u533A',
      '\u5927\u5174\u533A',
      '\u6000\u67D4\u533A',
      '\u5E73\u8C37\u533A',
      '\u5BC6\u4E91\u533A',
      '\u5EF6\u5E86\u533A'
    ]);
    // Tianjin districts
    add(1, 0, [
      '\u548C\u5E73\u533A',
      '\u6CB3\u4E1C\u533A',
      '\u6CB3\u897F\u533A',
      '\u5357\u5F00\u533A',
      '\u6CB3\u5317\u533A',
      '\u7EA2\u6865\u533A',
      '\u6EE8\u6D77\u65B0\u533A',
      '\u4E1C\u4E3D\u533A',
      '\u897F\u9752\u533A',
      '\u6D25\u5357\u533A',
      '\u5317\u8FB0\u533A',
      '\u6B66\u6E05\u533A',
      '\u5B9D\u5761\u533A',
      '\u84DF\u5DDE\u533A',
      '\u5B81\u6CB3\u533A',
      '\u9759\u6D77\u533A'
    ]);
    // Shanghai districts
    add(8, 0, [
      '\u9EC4\u6D66\u533A',
      '\u5F90\u6C47\u533A',
      '\u957F\u5B81\u533A',
      '\u9759\u5B89\u533A',
      '\u666E\u9640\u533A',
      '\u8679\u53E3\u533A',
      '\u6768\u6D66\u533A',
      '\u95F5\u884C\u533A',
      '\u5B9D\u5C71\u533A',
      '\u5609\u5B9A\u533A',
      '\u6D66\u4E1C\u65B0\u533A',
      '\u91D1\u5C71\u533A',
      '\u677E\u6C5F\u533A',
      '\u9752\u6D66\u533A',
      '\u5949\u8D24\u533A',
      '\u5D07\u660E\u533A'
    ]);
    // Chongqing districts
    add(21, 0, [
      '\u4E07\u5DDE\u533A',
      '\u6DAA\u9675\u533A',
      '\u6E1D\u4E2D\u533A',
      '\u5927\u6E21\u53E3\u533A',
      '\u6C5F\u5317\u533A',
      '\u6C99\u576A\u575D\u533A',
      '\u4E5D\u9F99\u5761\u533A',
      '\u5357\u5CB8\u533A',
      '\u5317\u789A\u533A',
      '\u6E1D\u5317\u533A',
      '\u5DF4\u5357\u533A',
      '\u7DA6\u6C5F\u533A',
      '\u5927\u8DB3\u533A',
      '\u6C38\u5DDD\u533A',
      '\u5357\u5DDD\u533A',
      '\u957F\u5BFF\u533A',
      '\u6C5F\u6D25\u533A',
      '\u5408\u5DDD\u533A',
      '\u94DC\u6881\u533A',
      '\u6F7C\u5357\u533A',
      '\u8363\u660C\u533A',
      '\u74A7\u5C71\u533A',
      '\u6881\u5E73\u533A',
      '\u57CE\u53E3\u53BF',
      '\u4E30\u90FD\u533A',
      '\u57AB\u6C5F\u53BF',
      '\u5FE0\u53BF',
      '\u5F00\u5DDE\u533A',
      '\u4E91\u9633\u53BF',
      '\u5949\u8282\u53BF',
      '\u5DEB\u5C71\u53BF',
      '\u5DEB\u6EAA\u53BF',
      '\u9ED4\u6C5F\u533A',
      '\u77F3\u67F1\u571F\u5BB6\u65CF\u81EA\u6CBB\u53BF',
      '\u79C0\u5C71\u571F\u5BB6\u65CF\u82D7\u65CF\u81EA\u6CBB\u53BF',
      '\u9149\u9633\u571F\u5BB6\u65CF\u82D7\u65CF\u81EA\u6CBB\u53BF',
      '\u5F6D\u6C34\u82D7\u65CF\u571F\u5BB6\u65CF\u81EA\u6CBB\u53BF',
      '\u6B66\u9686\u533A'
    ]);

    // Guangdong - major cities
    // Guangzhou
    add(18, 0, [
      '\u8354\u6E7E\u533A',
      '\u8D8A\u79C0\u533A',
      '\u6D77\u73E0\u533A',
      '\u5929\u6CB3\u533A',
      '\u767D\u4E91\u533A',
      '\u9EC4\u57D4\u533A',
      '\u756A\u79BA\u533A',
      '\u82B1\u90FD\u533A',
      '\u5357\u6C99\u533A',
      '\u4ECE\u5316\u533A',
      '\u589E\u57CE\u533A'
    ]);
    // Shenzhen
    add(18, 1, [
      '\u7F57\u6E56\u533A',
      '\u798F\u7530\u533A',
      '\u5357\u5C71\u533A',
      '\u5B9D\u5B89\u533A',
      '\u9F99\u5C97\u533A',
      '\u76D0\u7530\u533A',
      '\u9F99\u534E\u533A',
      '\u576A\u5C71\u533A',
      '\u5149\u660E\u533A',
      '\u5927\u9E4F\u65B0\u533A'
    ]);
    // Zhuhai
    add(18, 2,
        ['\u9999\u6D32\u533A', '\u6597\u95E8\u533A', '\u91D1\u6E7E\u533A']);
    // Foshan
    add(18, 4, [
      '\u7985\u57CE\u533A',
      '\u5357\u6D77\u533A',
      '\u987A\u5FB7\u533A',
      '\u4E09\u6C34\u533A',
      '\u9AD8\u660E\u533A'
    ]);
    // Dongguan
    add(18, 16, ['\u4E1C\u839E\u5E02']);
    // Zhongshan
    add(18, 17, ['\u4E2D\u5C71\u5E02']);

    // Jiangsu - major cities
    // Nanjing
    add(9, 0, [
      '\u7384\u6B66\u533A',
      '\u79E6\u6DEE\u533A',
      '\u5EFA\u90BA\u533A',
      '\u9F13\u697C\u533A',
      '\u6D66\u53E3\u533A',
      '\u6816\u971E\u533A',
      '\u96E8\u82B1\u53F0\u533A',
      '\u6C5F\u5B81\u533A',
      '\u516D\u5408\u533A',
      '\u6EA7\u6C34\u533A',
      '\u9AD8\u6DF3\u533A'
    ]);
    // Suzhou
    add(9, 4, [
      '\u59D1\u82CF\u533A',
      '\u864E\u4E18\u533A',
      '\u5434\u4E2D\u533A',
      '\u76F8\u57CE\u533A',
      '\u5434\u6C5F\u533A',
      '\u6606\u5C71\u5E02',
      '\u592A\u4ED3\u5E02',
      '\u5E38\u719F\u5E02',
      '\u5F20\u5BB6\u6E2F\u5E02'
    ]);

    // Zhejiang - major cities
    // Hangzhou
    add(10, 0, [
      '\u4E0A\u57CE\u533A',
      '\u4E0B\u57CE\u533A',
      '\u6C5F\u5E72\u533A',
      '\u62F1\u5885\u533A',
      '\u897F\u6E56\u533A',
      '\u6EE8\u6C5F\u533A',
      '\u8427\u5C71\u533A',
      '\u4F59\u676D\u533A',
      '\u4E34\u5E73\u533A',
      '\u94B1\u5858\u533A',
      '\u5BCC\u9633\u533A',
      '\u4E34\u5B89\u533A',
      '\u6850\u5E90\u53BF',
      '\u6DF3\u5B89\u53BF',
      '\u5EFA\u5FB7\u5E02'
    ]);
    // Ningbo
    add(10, 1, [
      '\u6D77\u66D9\u533A',
      '\u6C5F\u5317\u533A',
      '\u5317\u4ED1\u533A',
      '\u9547\u6D77\u533A',
      '\u911E\u5DDE\u533A',
      '\u5949\u5316\u533A',
      '\u6148\u6EAA\u5E02',
      '\u4F59\u59DA\u5E02',
      '\u5B81\u6D77\u53BF',
      '\u8C61\u5C71\u53BF'
    ]);

    // Sichuan - major cities
    // Chengdu
    add(22, 0, [
      '\u9526\u6C5F\u533A',
      '\u9752\u7F8A\u533A',
      '\u91D1\u725B\u533A',
      '\u6B66\u4FAF\u533A',
      '\u6210\u534E\u533A',
      '\u9F99\u6CC9\u9A7F\u533A',
      '\u9752\u767D\u6C5F\u533A',
      '\u65B0\u90FD\u533A',
      '\u6E29\u6C5F\u533A',
      '\u53CC\u6D41\u533A',
      '\u90EB\u90FD\u533A',
      '\u91D1\u5802\u53BF',
      '\u5927\u9091\u53BF',
      '\u84B2\u6C5F\u53BF',
      '\u65B0\u6D25\u533A',
      '\u90FD\u6C5F\u5830\u5E02',
      '\u5F6D\u5DDE\u5E02',
      '\u909B\u5D03\u5E02',
      '\u5D07\u5DDE\u5E02',
      '\u7B80\u9633\u5E02'
    ]);

    // Hubei - major cities
    // Wuhan
    add(16, 0, [
      '\u6C5F\u5CB8\u533A',
      '\u6C5F\u6C49\u533A',
      '\u4E54\u53E3\u533A',
      '\u6C49\u9633\u533A',
      '\u6B66\u660C\u533A',
      '\u9752\u5C71\u533A',
      '\u6D2A\u5C71\u533A',
      '\u4E1C\u897F\u6E56\u533A',
      '\u6C49\u5357\u533A',
      '\u8521\u7538\u533A',
      '\u6C5F\u590F\u533A',
      '\u9EC4\u9642\u533A',
      '\u65B0\u6D32\u533A'
    ]);

    // Henan - major cities
    // Zhengzhou
    add(15, 0, [
      '\u4E2D\u539F\u533A',
      '\u4E8C\u4E03\u533A',
      '\u7BA1\u57CE\u56DE\u65CF\u533A',
      '\u91D1\u6C34\u533A',
      '\u4E0A\u8857\u533A',
      '\u60E0\u6D4E\u533A',
      '\u4E2D\u7267\u53BF',
      '\u5DE9\u4E49\u5E02',
      '\u8365\u9633\u5E02',
      '\u65B0\u5BC6\u5E02',
      '\u65B0\u90D1\u5E02',
      '\u767B\u5C01\u5E02'
    ]);

    // Shandong - major cities
    // Jinan
    add(14, 0, [
      '\u5386\u4E0B\u533A',
      '\u5E02\u4E2D\u533A',
      '\u69D0\u836B\u533A',
      '\u5929\u6865\u533A',
      '\u5386\u57CE\u533A',
      '\u957F\u6E05\u533A',
      '\u7AE0\u4E18\u533A',
      '\u5E73\u9634\u53BF',
      '\u6D4E\u9633\u533A',
      '\u5546\u6CB3\u53BF',
      '\u6D4E\u5357\u9AD8\u65B0\u533A',
      '\u83B1\u829C\u533A'
    ]);
    // Qingdao
    add(14, 1, [
      '\u5E02\u5357\u533A',
      '\u5E02\u5317\u533A',
      '\u9EC4\u5C9B\u533A',
      '\u5D02\u5C71\u533A',
      '\u674E\u6CA7\u533A',
      '\u57CE\u9633\u533A',
      '\u5373\u58A8\u533A',
      '\u80F6\u5DDE\u5E02',
      '\u5E73\u5EA6\u5E02',
      '\u83B1\u897F\u5E02'
    ]);

    // Hunan - major cities
    // Changsha
    add(17, 0, [
      '\u8299\u84C9\u533A',
      '\u5929\u5FC3\u533A',
      '\u5CB3\u9E93\u533A',
      '\u5F00\u798F\u533A',
      '\u96E8\u82B1\u533A',
      '\u671B\u57CE\u533A',
      '\u957F\u6C99\u53BF',
      '\u6D4F\u9633\u5E02',
      '\u5B81\u4E61\u5E02'
    ]);

    // Hebei - major cities
    // Shijiazhuang
    add(2, 0, [
      '\u957F\u5B89\u533A',
      '\u6865\u897F\u533A',
      '\u65B0\u534E\u533A',
      '\u88D5\u534E\u533A',
      '\u4E95\u9649\u77FF\u533A',
      '\u9E7F\u6CC9\u533A',
      '\u85C1\u57CE\u533A',
      '\u6B63\u5B9A\u533A',
      '\u6816\u57CE\u533A'
    ]);

    // Fujian - major cities
    // Fuzhou
    add(12, 0, [
      '\u9F13\u697C\u533A',
      '\u53F0\u6C5F\u533A',
      '\u4ED3\u5C71\u533A',
      '\u9A6C\u5C3E\u533A',
      '\u664B\u5B89\u533A',
      '\u957F\u4E50\u533A',
      '\u798F\u6E05\u5E02',
      '\u95FD\u4FAF\u53BF',
      '\u8FDE\u6C5F\u53BF',
      '\u7F57\u6E90\u53BF',
      '\u95FD\u6E05\u53BF',
      '\u6C38\u6CF0\u53BF',
      '\u5E73\u6F6D\u7EFC\u5408\u5B9E\u9A8C\u533A'
    ]);
    // Xiamen
    add(12, 1, [
      '\u601D\u660E\u533A',
      '\u6E56\u91CC\u533A',
      '\u6D77\u6CA7\u533A',
      '\u96C6\u7F8E\u533A',
      '\u540C\u5B89\u533A',
      '\u7FD4\u5B89\u533A'
    ]);

    // For provinces/cities not explicitly listed above, return empty list
    // This covers all major cities - can be expanded as needed
    return m;
  }
}
