echo "Install the RTL8852BE s2idle Wi-Fi resume hook on machines that need it"

# Fresh installs get this from install/hardware/realtek/fix-rtw89-8852be-resume.sh.
# Existing installs never ran that leaf. The hook is hardware-conditional and is
# not packaged for every machine; copy it only when the chip is present.

src="${OMARCHY_RTW89_HOOK_SRC:-$OMARCHY_PATH/default/systemd/system-sleep/rtw89-8852be}"
dest="${OMARCHY_RTW89_HOOK_DST:-/usr/lib/systemd/system-sleep/rtw89-8852be}"

# Buffer lspci before matching. A piped grep can SIGPIPE a chatty lspci
# under pipefail and look like "no such hardware" (#6608).
pci_info=$(lspci -nn)

if [[ $pci_info != *'[10ec:b852]'* ]]; then
  exit 0
fi

# A matching copy counts only if systemd-sleep will run it and only root can change it.
if [[ -f $dest && ! -L $dest ]] && cmp -s "$src" "$dest" && [[ $(stat -c '%u:%g %a' -- "$dest") == "0:0 755" ]]; then
  exit 0
fi

# Publish a new root-owned inode rather than rewriting whatever is at $dest,
# as migrations/1788662350.sh does for the other sleep hooks.
sudo mkdir -p "$(dirname "$dest")"
stage=$(sudo mktemp -- "${dest%/*}/.${dest##*/}.omarchy.XXXXXX")
sudo install -m 0755 -o root -g root -T "$src" "$stage"
sudo mv -Tf -- "$stage" "$dest"
