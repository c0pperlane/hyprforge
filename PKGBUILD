# Maintainer: Manu <c0pperlane/hyprforge>
pkgname=hyprforge
pkgver=1.0.0
pkgrel=1
pkgdesc="A desktop widget designer for Hyprland"
arch=('any')
url="https://github.com/c0pperlane/hyprforge"
license=('custom:MIT-link')
depends=('quickshell' 'hyprland' 'python')
optdepends=(
    'caelestia-shell: C++ system metrics, audio spectrum and lyrics'
    'nvidia-utils: GPU readings on NVIDIA without caelestia-shell'
)
source=("$pkgname-$pkgver.tar.gz::$url/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('SKIP')

package() {
    cd "$srcdir/$pkgname-$pkgver"

    # The shell itself, as a Quickshell config root. /etc/xdg is where
    # Quickshell looks for system-wide configs (XDG_CONFIG_DIRS), which is
    # also where caelestia-shell installs its own.
    install -d "$pkgdir/etc/xdg/quickshell/$pkgname"
    for d in shell.qml components config editor layer services widgets samples assets; do
        [ -e "$d" ] && cp -a "$d" "$pkgdir/etc/xdg/quickshell/$pkgname/"
    done

    install -Dm755 "bin/$pkgname"        "$pkgdir/usr/bin/$pkgname"
    install -Dm755 "bin/$pkgname-fonts"  "$pkgdir/usr/bin/$pkgname-fonts"
    install -Dm644 "systemd/$pkgname.service" \
        "$pkgdir/usr/lib/systemd/user/$pkgname.service"
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"

    install -Dm644 /dev/stdin "$pkgdir/usr/share/applications/$pkgname.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Desktop Designer
GenericName=Widget designer
Comment=Design your Hyprland desktop: widgets, layout, snapping
Exec=$pkgname toggle
Icon=preferences-desktop-theme
Terminal=false
Categories=Utility;DesktopSettings;
Keywords=widget;desktop;hyprforge;quickshell;
DESKTOP
}
