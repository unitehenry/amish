if [ -n "${USERNAME}" ] && [ -n "${PASSWORD}" ]; then
    PASS_HASH=$(echo -n "${PASSWORD}" | md5sum | awk '{print $1}')
    sed -i "s/__USERNAME__/${USERNAME}/g" /etc/guacamole/user-mapping.xml
    sed -i "s/__PASSWORD__/${PASS_HASH}/g" /etc/guacamole/user-mapping.xml
fi
