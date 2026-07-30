#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

class Utils {
 public:
  static void InitializeCOM();
  static std::vector<std::string> ConvertFlutterArgsToCommandLineArguments();
};

#endif
