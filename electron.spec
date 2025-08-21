%global electon_version 37.2.3

Name:		electron-%{electon_version}
Version:	1
Release:	1
Source0:	%{name}.tar.gz
Summary:	Test
URL:		https://github.com/electron/electron
License:	GPL
Group:		Test

BuildRequires:	ninja
BuildRequires:  gn

%description

%prep
%autosetup -p1 -n %{name}
cd src
export CHROMIUM_BUILDTOOLS_PATH=`pwd`/buildtools
gn gen out/Release --args="import(\"//electron/build/args/release.gn\")"

%build
ninja -C out/Release electron
electron/script/strip-binaries.py -d out/Release
ninja -C out/Release electron:electron_dist_zip

%install


%files
