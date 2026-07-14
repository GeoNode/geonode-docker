#!/bin/bash

auth_conf_source="$1"
auth_conf_target="$2"
# Creating a temporary file for sed to write the changes to
temp_file="xml.tmp"
touch $temp_file

source /root/.bashrc
source /root/.override_env

test -z "$auth_conf_source" && echo "You must specify a source file" && exit 1
test -z "$auth_conf_target" && echo "You must specify a target conf directory" && exit 1

test ! -f "$auth_conf_source" && echo "Source $auth_conf_source does not exist or is not a file" && exit 1
test ! -d "$auth_conf_target" && echo "Target directory $auth_conf_target does not exist or is not a directory" && exit 1

# for debugging
echo -e "OAUTH2_API_KEY=$OAUTH2_API_KEY\n"
echo -e "OAUTH2_CLIENT_ID=$OAUTH2_CLIENT_ID\n"
echo -e "OAUTH2_CLIENT_SECRET=$OAUTH2_CLIENT_SECRET\n"
echo -e "GEOSERVER_LOCATION=$GEOSERVER_LOCATION\n"
echo -e "GEONODE_LOCATION=$GEONODE_LOCATION\n"
echo -e "GEONODE_GEODATABASE=$GEONODE_GEODATABASE\n"
echo -e "GEONODE_GEODATABASE_USER=$GEONODE_GEODATABASE_USER\n"
echo -e "GEONODE_GEODATABASE_PASSWORD=$GEONODE_GEODATABASE_PASSWORD\n"
echo -e "auth_conf_source=$auth_conf_source\n"
echo -e "auth_conf_target=$auth_conf_target\n"

# Elegance is the key -> adding an empty last line for Mr. “sed” to pick up
echo " " >> "$auth_conf_source"

cat "$auth_conf_source"

tagname=( ${@:3:7} )

# for debugging
for i in "${tagname[@]}"
do
   echo "tagname=<$i>"
done

echo "DEBUG: Starting... [Ok]\n"

# Escape a string for safe use in sed's REGEX (pattern) side, given @ delimiter
escape_regex() {
    printf '%s' "$1" | sed -e 's/[][\\.^$*+?(){}|@/-]/\\&/g'
}

# Escape a string for safe use in sed's REPLACEMENT side, given @ delimiter
escape_replacement() {
    printf '%s' "$1" | sed -e 's/[\\&@/]/\\&/g'
}

for i in "${tagname[@]}"
do
    echo "DEBUG: Working on '$auth_conf_source' for tagname <$i>"
    # Extracting the value from the <$tagname> element
    # echo -ne "<$i>$tagvalue</$i>" | xmlstarlet sel -t -m "//a" -v . -n
    tagvalue=`grep "<$i>.*<.$i>" "$auth_conf_source" | sed -e "s/^.*<$i/<$i/" | cut -f2 -d">"| cut -f1 -d"<"`

    echo "DEBUG: Found the current value for the element <$i> - '$tagvalue'"

    # Setting new substituted value
    case $i in
        authApiKey)
            newvalue="$OAUTH2_API_KEY";;
        cliendId)
            newvalue="$OAUTH2_CLIENT_ID";;
        clientSecret)
            newvalue="$OAUTH2_CLIENT_SECRET";;
        proxyBaseUrl | redirectUri | userAuthorizationUri | logoutUri )
            newvalue=`printf '%s' "$tagvalue" | sed -re "s@^(https?://[^/]+)@${GEOSERVER_LOCATION%/}@"`;;
        baseUrl | accessTokenUri | checkTokenEndpointUrl )
            newvalue=`printf '%s' "$tagvalue" | sed -re "s@^(https?://[^/]+)@${GEONODE_LOCATION%/}@"`;;
        *) echo "an unknown variable has been found"; continue;;
    esac

    echo "DEBUG: Found the new value for the element <$i> - '$newvalue'"

    # Match the whole element (empty or not); only the tag name is interpolated,
    # so the user-controlled content goes through the escapers.
    new_esc=`escape_replacement "$newvalue"`
    sed -E "s@(<$i>)[^<]*(</$i>)@\1${new_esc}\2@g" "$auth_conf_source" > "$temp_file"
    cp "$temp_file" "$auth_conf_source"
done
# Writing our changes back to the original file ($auth_conf_source)
# no longer needed
# mv $temp_file $auth_conf_source

echo "DEBUG: Finished... [Ok] --- Final xml file is \n"
cat "$auth_conf_source"
