#include "platform.hpp"

#include "../coding/file_reader.hpp"

#include <dirent.h>
#include <sys/stat.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSProcessInfo.h>

#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
#import <UIKit/UIScreenMode.h>

class Platform::PlatformImpl
{
public:
  double m_visualScale;
  int m_scaleEtalonSize;
  string m_skinName;
  string m_deviceName;
};

Platform::Platform()
{
  m_impl = new PlatformImpl;

  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

  NSBundle * bundle = [NSBundle mainBundle];
  NSString * path = [bundle resourcePath];
  m_resourcesDir = [path UTF8String];
  m_resourcesDir += '/';

  NSArray * dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString * docsDir = [dirPaths objectAtIndex:0];
  m_writableDir = [docsDir UTF8String];
  m_writableDir += '/';

  // Hardcoding screen resolution depending on the device we are running.
  m_impl->m_visualScale = 1.0;
  m_impl->m_skinName = "basic.skn";

  // Calculating resolution
  UIDevice * device = [UIDevice currentDevice];

  NSRange range = [device.model rangeOfString:@"iPad"];
  if (range.location != NSNotFound)
  {
    m_impl->m_deviceName = "iPad";
    m_impl->m_visualScale = 1.3;
  }
  else
  {
    range = [device.model rangeOfString:@"iPod"];
    if (range.location != NSNotFound)
      m_impl->m_deviceName = "iPod";
    else
      m_impl->m_deviceName = "iPhone";
    if ([UIScreen mainScreen].currentMode.size.width == 640)
    {
      m_impl->m_visualScale = 2.0;
      m_impl->m_skinName = "basic_highres.skn";
    }
  }

  m_impl->m_scaleEtalonSize = 256 * 1.5 * m_impl->m_visualScale;

  NSLog(@"Device: %@, SystemName: %@, SystemVersion: %@", device.model, device.systemName, device.systemVersion);

  [pool release];
}

Platform::~Platform()
{
  delete m_impl;
}

void Platform::GetFilesInDir(string const & directory, string const & mask, FilesList & res) const
{
  DIR * dir;
  struct dirent * entry;

  if ((dir = opendir(directory.c_str())) == NULL)
    return;

  // TODO: take wildcards into account...
  string mask_fixed = mask;
  if (mask_fixed.size() && mask_fixed[0] == '*')
    mask_fixed.erase(0, 1);

  do
  {
    if ((entry = readdir(dir)) != NULL)
    {
      string fname(entry->d_name);
      size_t index = fname.rfind(mask_fixed);
      if (index != string::npos && index == fname.size() - mask_fixed.size())
      {
        // TODO: By some strange reason under simulator stat returns -1,
        // may be because of symbolic links?..
        //struct stat fileStatus;
        //if (stat(string(directory + fname).c_str(), &fileStatus) == 0 &&
        //    (fileStatus.st_mode & S_IFDIR) == 0)
        //{
          res.push_back(fname);
        //}
      }
    }
  } while (entry != NULL);

  closedir(dir);
}

bool Platform::GetFileSize(string const & file, uint64_t & size) const
{
  struct stat s;
  if (stat(file.c_str(), &s) == 0)
  {
    size = s.st_size;
    return true;
  }
  return false;
}

void Platform::GetFontNames(FilesList & res) const
{
  GetFilesInDir(ResourcesDir(), "*.ttf", res);
  sort(res.begin(), res.end());
}

static string ReadPathForFile(string const & writableDir,
    string const & resourcesDir, string const & file)
{
  string fullPath = writableDir + file;
  if (!GetPlatform().IsFileExists(fullPath))
  {
    fullPath = resourcesDir + file;
    if (!GetPlatform().IsFileExists(fullPath))
      MYTHROW(FileAbsentException, ("File doesn't exist", fullPath));
  }
  return fullPath;
}

ModelReader * Platform::GetReader(string const & file) const
{
  return new FileReader(ReadPathForFile(m_writableDir, m_resourcesDir, file), 10, 12);
}

int Platform::CpuCores() const
{
  NSInteger const numCPU = [[NSProcessInfo processInfo] activeProcessorCount];
  if (numCPU >= 1)
    return numCPU;
  return 1;
}

string Platform::SkinName() const
{
  return m_impl->m_skinName;
}

double Platform::VisualScale() const
{
  return m_impl->m_visualScale;
}

int Platform::ScaleEtalonSize() const
{
  return m_impl->m_scaleEtalonSize;
}

int Platform::MaxTilesCount() const
{
  return 120;
}

int Platform::TileSize() const
{
  return 256;
}

string Platform::DeviceName() const
{
  return m_impl->m_deviceName;
}

////////////////////////////////////////////////////////////////////////
extern "C" Platform & GetPlatform()
{
  static Platform platform;
  return platform;
}
