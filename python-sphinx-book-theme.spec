Name:		python-sphinx-book-theme
Version:	1.1.4
Release:	1
Source0:	https://files.pythonhosted.org/packages/source/s/sphinx_book_theme/sphinx_book_theme-%{version}.tar.gz
Source1:	sphinx_book_theme-%{version}-vendor.tar.xz
Source100:	prepare_vendor.sh
Summary:	A clean book theme for scientific explanations and documentation with Sphinx
URL:		https://pypi.org/project/sphinx-book-theme/
License:	BSD 3-Clause
Group:		Development/Python
BuildRequires:	python
BuildRequires:	python%{pyver}dist(sphinx-theme-builder)
BuildRequires:	python%{pyver}dist(nodeenv)
BuildRequires:	nodejs
BuildRequires:	yarn
BuildSystem:	python
BuildArch:	noarch

%global node_version %(node --version |sed -e 's,^v,,')
%global pdst %(rpm -q --qf '%%{VERSION}' python-pydata-sphinx-theme)

%description
A clean book theme for scientific explanations and documentation with Sphinx

%prep
%autosetup -p1 -a1 -n sphinx_book_theme-%{version}
sed -i -e 's,^node-version =.*,node-version = "%{node_version}",' pyproject.toml
sed -i -e 's,pydata-sphinx-theme==,pydata-sphinx-theme>=,' pyproject.toml PKG-INFO

%build -p
export YARN_CACHE_FOLDER="$(pwd)/.package-cache"
yarn install --offline
nodeenv --node=system --prebuilt --clean-src $(pwd)/.nodeenv

%files
%{py_sitedir}/sphinx_book_theme
%{py_sitedir}/sphinx_book_theme-*.*-info
