ROUTE=$(mdata-get route 2>/dev/null) || \
unset ROUTE;

if [[ -z ${ROUTE+x} ]]; then 
	echo "Route is unset; we are assuming it is not needed." 
else 
	route add default ${ROUTE}
fi


echo "master: "$(mdata-get salt-master) >> /opt/salt/etc/minion  
echo "id: "$(mdata-get salt-id) >> /opt/salt/etc/minion 

#mkdir /data/salt/pki/minion
mkdir -p /opt/salt/etc/pki/minion
chmod 700 /opt/salt/etc/pki/minion
mdata-get salt-pem > /opt/salt/etc/pki/minion/minion.pem
chmod 400 /opt/salt/etc/pki/minion/minion.pem
mdata-get salt-pub > /opt/salt/etc/pki/minion/minion.pub
chmod 644 /opt/salt/etc/pki/minion/minion.pub
/usr/sbin/svcadm enable salt-minion

/opt/salt/bin/salt-call state.highstate