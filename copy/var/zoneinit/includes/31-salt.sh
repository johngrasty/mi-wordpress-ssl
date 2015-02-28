
echo "master: "$(mdata-get salt-master) >> /opt/salt/etc/minion  
echo "id: "$(mdata-get salt-id) >> /opt/salt/etc/minion 

#mkdir /data/salt/pki/minion
mdata-get salt-pem > /opt/salt/etc/pki/minion/minion.pem
mdata-get salt-pub > /opt/salt/etc/pki/minion/minion.pub
/usr/sbin/svcadm enable salt-minion

salt-call state-highstate