#!/bin/bash 
echo "==========================================================================================="
echo "Initiating Satellite 6.3 GA system registration and configuration setup..[Internal use only]"
echo "===========================================================================================
"
trap ctrl_c INT
	function ctrl_c() {
		echo "**Trapped CTRL-C**"  ; exit
}

#System information.
echo "System Information:"
echo "########################################"
echo "Hostname:"
hostname
echo "########################################"
cat '/etc/redhat-release'
echo "########################################"
echo "Memory Info:"
free -m
echo "########################################"
echo "Disk Info:"
df -h 
echo "########################################"
echo "Date:"
date
echo "########################################"

echo "

"

#Installer details.

echo "Please provide Satellite Installer details"

echo "Organization Name:"
unset org
while [ -z ${org} ]; do
     read org
done

echo "Location Name:"
unset loc
while [ -z ${loc} ]; do
     read loc
done

echo "Admin Username:"
unset username
while [ -z ${username} ]; do
     read username
done

echo "Admin Password:"
unset passwd
while [ -z ${passwd} ]; do
     read passwd
done

read -p "Do you wish to install Satellite with above parameters. STOP the installer if 'DNS' is not configured properly.  Y/N: "   -n 1 -r
echo "
"
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi


echo "
"


#Registration.
echo "Registering system to the RHSM, Red Hat portal credentials required"

subscription-manager register --force
RESULT=$?
if [ $RESULT -eq 0 ]; then
        echo "Registration Successful!"
else
        echo "Registration Failed :("
        exit 1
fi

echo "
"

#Subscription.
echo "Attaching Employee Satellite subscription"
sub=`subscription-manager list --matches="Red Hat Satellite Employee Subscription" --all --available | grep "Pool ID:" | awk '{print $3}' |head -n1`
subscription-manager attach --pool="$sub"
RESULT=$?
if [ $RESULT -eq 0 ]; then
        echo "Satellite Subsription Attached!"
else
        echo "Failed to attach Subscription :("
        exit 1
fi

echo "
"

#Enable repos. 
echo "Enabling required repositories..."
subscription-manager repos --disable "*" --enable=rhel-7-server-rpms --enable=rhel-server-rhscl-7-rpms --enable=rhel-7-server-satellite-6.3-rpms

#Update the system.
yum clean all
yum update -y

echo "
"

#Install the Satellite server.
echo "Insatlling Satellite server..."
yum install satellite -y


echo "
"

#Configure the Satellite server.
echo "******************************************"
echo "Executing Installer with below parameters"
echo "------------------------------------------"
echo "Org:$org"
echo "------------------------------------------"
echo "Location:$loc"
echo "------------------------------------------"
echo "User:$username    Password:$passwd"
echo "******************************************"

echo "
"
satellite-installer --scenario satellite --foreman-initial-organization "$org" --foreman-initial-location "$loc" --foreman-admin-username "$username" --foreman-admin-password "$passwd" --foreman-proxy-dns-managed=false --foreman-proxy-dhcp-managed=false --disable-system-checks
RESULT=$?
if [ $RESULT -eq 0 ]; then
        echo "Yippee! Configuration Completed :)"

 else
        echo "Installation Failed :( "
        exit 1
fi



