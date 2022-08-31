/** collector

A full notice with attributions is provided along with this source code.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License version 2 as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

* In addition, as a special exception, the copyright holders give
* permission to link the code of portions of this program with the
* OpenSSL library under certain conditions as described in each
* individual source file, and distribute linked combinations
* including the two.
* You must obey the GNU General Public License in all respects
* for all of the code used other than OpenSSL.  If you modify
* file(s) with this exception, you may extend this exception to your
* version of the file(s), but you are not obligated to do so.  If you
* do not wish to do so, delete this exception statement from your
* version.
*/

#include "Diagnostics.h"

#include <fstream>
#include <iterator>
#include <streambuf>
#include <string>

#include "HostInfo.h"
#include "Utility.h"

namespace collector {

namespace {

/**
 *
 */
std::string readFileIfExists(const std::string& filename) {
  std::ifstream file(filename);
  if (file.is_open()) {
    return std::string((
        std::istreambuf_iterator<char>(file),
        std::istreambuf_iterator<char>()));
  }
  return "";
}

std::string readHostFileIfExists(const std::string& filename) {
  return readFileIfExists(GetHostPath(filename));
}

/**
 * @brief checks whether the kernel supports unsigned Kernel Module
 *        insertion.
 */
bool kernelSupportsModules() {
  return readHostFileIfExists("/proc/sys/kernel/modules_disabled") == "0";
}

/**
 *
 */
bool kernelSupportsUnsignedModules(const HostInfo& host) {
}

}  // namespace

void DumpDiagnosticInformation(std::ostream& output) {
  const HostInfo& host = HostInfo::Instance();
  output << "System Diagnostics:" << std::endl;
  output << "Kernel version:                   " << host.GetKernelVersion().release;
  // this can give clues about signed kernel modules and other kernel options.
  output << "Kernel command line:              " << readHostFileIfExists("/proc/cmdline") << std::endl;
  output << "Kernel supports module insertion? " << kernelSupportsModules() << std::endl;
  output << "Kernel supports eBPF?             " << host.GetKernelVersion().HasEBPFSupport() << std::endl;
}

}  // namespace collector
