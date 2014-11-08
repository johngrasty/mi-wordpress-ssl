
log "enabling http services"
svcadm enable nginx
svcadm enable php-fpm
#svcadm enable memcached


# Get password from metadata, unless passed as MYSQL_PW, or set one.
log "getting mysql_pw"
MYSQL_PW=${MYSQL_PW:-$(mdata-get mysql_pw 2>/dev/null)} || \
MYSQL_PW=$(od -An -N8 -x /dev/random | head -1 | tr -d ' ');
gsed -i "s/%MYSQL_PW%/${MYSQL_PW}/" /etc/motd


WP_PW=$MYSQL_PW

log "determine the webui address for the motd"

WEBUI_ADDRESS=$PRIVATE_IP

if [[ ! -z $PUBLIC_IP ]]; then
        WEBUI_ADDRESS=$PUBLIC_IP
fi

log "mdata-get wordpress metadata"

MYSQL_HOST=${MYSQL_HOST:-$(mdata-get mysql_host 2>/dev/null)} || \
MYSQL_HOST="10.0.0.4";

MYSQL_NAME=${MYSQL_NAME:-$(mdata-get wpdb_name 2>/dev/null)} || \
MYSQL_NAME="wordpressdb";

MYSQL_USER=${MYSQL_USER:-$(mdata-get wpdb_user 2>/dev/null)} || \
MYSQL_USER="wordpressdba";

TABLE_PREFIX=${TABLE_PREFIX:-$(mdata-get table_prefix 2>/dev/null)} || \
TABLE_PREFIX="_wpmy";

WPSITE_TITLE=${WPSITE_TITLE:-$(mdata-get wpsite_title 2>/dev/null)} || \
WPSITE_TITLE="Wordpress Site";

WPSITE_URL=${WPSITE_URL:-$(mdata-get wpsite_url 2>/dev/null)} || \
WPSITE_URL=${WEBUI_ADDRESS};

WPHOME_URL=${WPHOME_URL:-$(mdata-get wphome_url 2>/dev/null)} || \
WPHOME_URL=${WEBUI_ADDRESS};

WPADMIN_USR=${WPADMIN_USR:-$(mdata-get wpadmin_usr 2>/dev/null)} || \
WPADMIN_USR="wpadmin";

WPADMIN_PSW=${WPADMIN_PSW:-$(mdata-get wpadmin_psw 2>/dev/null)} || \
WPADMIN_PSW="wppass";

WPADMIN_EMA=${WPADMIN_EMA:-$(mdata-get wpadmin_ema 2>/dev/null)} || \
WPADMIN_EMA="admin@site.local";

INSTALL=${INSTALL:-$(mdata-get install 2>/dev/null)} || \
INSTALL="true";

log "Installing Wordpress via wp_cli"

cd /data/www/wordpress ||
mkdir -p /data/www/wordpress && chown -R www:www /data/www/ && cd /data/www/wordpress;

# This test won't work. It checks to see if the table are installed
# It will be better test if the config file is there.
#if ! $(/opt/local/bin/wp core is-installed); then

if [[ ${INSTALL} == "true" ]], then
	/opt/local/bin/wp core download
	/opt/local/bin/wp core config --dbname="${MYSQL_NAME}" --dbuser="${MYSQL_USER}" --dbpass="${WP_PW}" --dbprefix="${TABLE_PREFIX}"
	/opt/local/bin/wp core install --url="${WPSITE_URL}" --title="${WPSITE_TITLE}" --admin_user="${WPADMIN_USR}" --admin_password="${WPADMIN_PSW}" --admin_email="${WPADMIN_EMA}"
	/opt/local/bin/wp plugin install wordpress-seo
	/opt/local/bin/wp plugin install nginx-helper
	/opt/local/bin/wp plugin activate wordpress-seo
	/opt/local/bin/wp plugin activate nginx-helper
	/opt/local/bin/wp rewrite structure '/%postname%/'
fi

if [[ -e wp-config.php ]], then 
log "customizing wp-config.php"
gsed -i "37i define ('WP_POST_REVISIONS', 4);" /data/www/wordpress/wp-config.php
gsed -i "38i define('DISALLOW_FILE_EDIT', true);" /data/www/wordpress/wp-config.php
gsed -i "39i define('DISABLE_WP_CRON', true);" /data/www/wordpress/wp-config.php
fi

log "customizing cron"
crontab -l > /tmp/mycron
echo "45 * * * * /opt/local/bin/php /data/www/wordpress/wp-cron.php >/dev/null 2>&1" >> /tmp/mycron
crontab /tmp/mycron

gsed -i "s/%WEBUI_ADDRESS%/${WEBUI_ADDRESS}/" /etc/motd
# gsed -i "s/%WP_PW%/${WP_PW}/" /etc/motd
gsed -i "s/%WPSITE_URL%/${WPSITE_URL}/" /etc/motd
gsed -i "s/%WPADMIN_USR%/${WPADMIN_USR}/" /etc/motd
gsed -i "s/%WPADMIN_PSW%/${WPADMIN_PSW}/" /etc/motd
