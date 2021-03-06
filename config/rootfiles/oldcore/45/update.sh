#!/bin/bash
############################################################################
#                                                                          #
# This file is part of the IPFire Firewall.                                #
#                                                                          #
# IPFire is free software; you can redistribute it and/or modify           #
# it under the terms of the GNU General Public License as published by     #
# the Free Software Foundation; either version 3 of the License, or        #
# (at your option) any later version.                                      #
#                                                                          #
# IPFire is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of           #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            #
# GNU General Public License for more details.                             #
#                                                                          #
# You should have received a copy of the GNU General Public License        #
# along with IPFire; if not, write to the Free Software                    #
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA #
#                                                                          #
# Copyright (C) 2010 IPFire-Team <info@ipfire.org>.                        #
#                                                                          #
############################################################################
#
. /opt/pakfire/lib/functions.sh
/usr/local/bin/backupctrl exclude >/dev/null 2>&1

#
# Remove old core updates from pakfire cache to save space...
core=45
for (( i=1; i<=$core; i++ ))
do
	rm -f /var/cache/pakfire/core-upgrade-*-$i.ipfire
done

#
#Stop services
echo Stopping Proxy
/etc/init.d/squid stop 2>/dev/null
echo Stopping vpn-watch
killall vpn-watch

#
#Extract files
extract_files

#
# Remove some addon cronjobs if the addons are not installed
[ ! -e /opt/pakfire/db/installed/meta-cacti ] && rm -f /etc/fcron.cyclic/cacti.cron
[ ! -e /opt/pakfire/db/installed/meta-gnump3d ] && rm -f /etc/fcron.daily/gnump3d-index
[ ! -e /opt/pakfire/db/installed/meta-asterisk ] && rm -f /etc/fcron.minutely/wakeup.sh

# Remove disable cron mails...
sed "s|MAILTO=root|MAILTO=|g" < /var/spool/cron/root.orig > /var/tmp/root.tmp
fcrontab /var/tmp/root.tmp

# Disable snort packet decoding alerts
sed -i "s|#config disable_decode_alerts|config disable_decode_alerts|g" /etc/snort/snort.conf
sed -i "s|#config disable_tcpopt_alerts|config disable_tcpopt_alerts|g" /etc/snort/snort.conf

#
#Start services
echo Starting Proxy
/etc/init.d/squid start 2>/dev/null
echo Rewriting Outgoing FW Rules
/var/ipfire/outgoing/bin/outgoingfw.pl
if [ `grep "ENABLED=on" /var/ipfire/vpn/settings` ]; then
	echo Starting vpn-watch
	/usr/local/bin/vpn-watch &
fi

#
#Update Language cache
#perl -e "require '/var/ipfire/lang.pl'; &Lang::BuildCacheLang"

#Disable geode_aes modul
mv /lib/modules/2.6.32.28-ipfire/kernel/drivers/crypto/geode-aes.ko \
   /lib/modules/2.6.32.28-ipfire/kernel/drivers/crypto/geode-aes.ko.off >/dev/null 2>&1
mv /lib/modules/2.6.32.28-ipfire-pae/kernel/drivers/crypto/geode-aes.ko \
   /lib/modules/2.6.32.28-ipfire-pae/kernel/drivers/crypto/geode-aes.ko.off >/dev/null 2>&1
mv /lib/modules/2.6.32.28-ipfire-xen/kernel/drivers/crypto/geode-aes.ko \
   /lib/modules/2.6.32.28-ipfire-xen/kernel/drivers/crypto/geode-aes.ko.off >/dev/null 2>&1

#Rebuild module dep's
depmod 2.6.32.28-ipfire     >/dev/null 2>&1
depmod 2.6.32.28-ipfire-pae >/dev/null 2>&1
depmod 2.6.32.28-ipfire-xen >/dev/null 2>&1

#
#Finish
#Don't report the exitcode last command
exit 0
