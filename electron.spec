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
BuildRequires:	gperf
BuildRequires:	pkgconfig(glib)
BuildRequires:	cargo

%description

%prep
%autosetup -p1 -n src
export CHROMIUM_BUILDTOOLS_PATH=`pwd`/buildtools
gn gen out/Release --args="import(\"//electron/build/args/release.gn\")"

%build
ninja -C out/Release electron
electron/script/strip-binaries.py -d out/Release
ninja -C out/Release electron:electron_dist_zip

%install
install -dm0755 %{buildroot}%{_libdir}/%{name}
bsdtar -xf out/Release/dist.zip %{buildroot}%{_libdir}/%{name}
chmod u+s %{buildroot}%{_libdir}/%{name}/chrome-sandbox


%files
%license LICENSE LICENSE.chromium.html
%{_libdir}/%{name}
