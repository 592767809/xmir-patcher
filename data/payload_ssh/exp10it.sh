# enable UART
nvram set boot_wait=on
nvram set bootdelay=3
nvram set uart_en=1
nvram commit

# change password for root
echo -e "root\nroot" | (passwd root) 

kill -9 `pgrep dropbearmulti` &>/dev/null

[ ! -e /tmp/dropbearmulti_0 ] && return 1
[ ! -e /tmp/dropbearmulti_1 ] && return 1
[ ! -e /tmp/dropbear.init.d.sh ] && return 1

rm -f /tmp/dropbearmulti
rm -f /tmp/dropbearmulti.gz
cat /tmp/dropbearmulti_* >> /tmp/dropbearmulti.gz
gzip -c -d /tmp/dropbearmulti.gz > /tmp/dropbearmulti
[ "$?" = "0" ] || return 1
chmod +x /tmp/dropbearmulti
rm -f /tmp/dropbearmulti_*
rm -f /tmp/dropbearmulti.gz

if [ ! -d /etc/dropbear ]; then
	mkdir /etc/dropbear
	chown root /etc/dropbear
	chmod 0700 /etc/dropbear
fi

# generate host key
if [ ! -s /etc/dropbear/dropbear_ed25519_host_key ]; then
	rm -f /etc/dropbear/dropbear_ed25519_host_key
	/tmp/dropbearmulti dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key 2>&- >&-
fi

if [ ! -s /etc/dropbear/dropbear_ecdsa_host_key ]; then
	rm -f /etc/dropbear/dropbear_ecdsa_host_key
	/tmp/dropbearmulti dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key 2>&- >&-
fi

# start SSH server
/tmp/dropbearmulti -p 122

#kill -9 `pgrep taskmonitor` &>/dev/null

# unlock and restart preintalled dropbear (devel firmware)
if [ -f /etc/init.d/dropbear ]; then
	# unlock autostart dropbear
	sed -i 's/"$flg_ssh" != "1" -o "$channel" = "release"/-n ""/g' /etc/init.d/dropbear
	if [ -f /usr/sbin/dropbear ]; then
		# enable dropbear
		/etc/init.d/dropbear enable &>/dev/null 
		# restart dropbear
		/etc/init.d/dropbear restart
	fi
fi

# install dropbear for release firmware (not devel)
if [ ! -f /usr/sbin/dropbear -o ! -f /etc/init.d/dropbear ]; then
	kill -9 `pgrep dropbear$` &>/dev/null

	rm -f /etc/dropbear/dropbear
	cp -f /tmp/dropbearmulti /etc/dropbear/dropbear
	chmod +x /etc/dropbear/dropbear

	rm -f /etc/config/dropbear
	cp -f /tmp/dropbear.uci.cfg /etc/config/dropbear

	rm -f /etc/init.d/dropbear
	cp -f /tmp/dropbear.init.d.sh /etc/init.d/dropbear
	chmod +x /etc/init.d/dropbear

	rm -f /etc/rc.d/K50dropbear
	ln -s /etc/init.d/dropbear /etc/rc.d/K50dropbear &>/dev/null

	rm -f /etc/rc.d/S50dropbear
	ln -s /etc/init.d/dropbear /etc/rc.d/S50dropbear &>/dev/null

	# enable dropbear
	/etc/init.d/dropbear enable &>/dev/null 

	# restart dropbear
	/etc/init.d/dropbear restart
fi
#rm -f /tmp/dropbear.uci.cfg
#rm -f /tmp/dropbear.init.d.sh

