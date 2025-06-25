# unifi_rclone.webdav_radius_auth
Simple <b>Webdav Server</b> for Unifi Dream Machine based on Rclone (comparable to my <a href="https://github.com/emsi76/unifi_rclone.webdav">previous one</a> ) additionally <b>authenticating users against built-in radius server</b>
<p>
Transform your Unifi gateway to a NAS with this simple multi-user <a href="http://www.webdav.org">Webdav</a> Server for Unifi Dream Machine (UDM) based on <a href="https://github.com/rclone/rclone">rclone</a>.
</p>
<p>
<ul>
  <li>Configurable webdav port and root path - which can also be configured to your disk (hdd/sdd)</li>
  <li>User authentication is done against built-in radius server, so no further user management required</li>
  <li>Each user gets his own dedicated "home" folder under the overall webdav root</li>
  <li>Secured with https using the certs of the UDM</li>
  <liAuthentication fails lead to a banned user's webdav folder</li>
  <li>Low consumption of resources (CPU / Mem)</li>
</ul>
</p>
<p>
Easy 1 step <a href="https://github.com/emsi76/unifi_rclone.webdav_radius_auth/blob/main/README.md#installation">installation</a> and 2 step <a href="https://github.com/emsi76/unifi_rclone.webdav_radius_auth#configuration">configuration</a> should not take more than some minutes! :-)  
</p>
<p>
  This set of scripts installs rclone as WebDav Server - see <a href="https://rclone.org/commands/rclone_serve_webdav/">rclone serve webdav</a> and set it up as service on your UDM with a custom <a href="https://rclone.org/commands/rclone_serve_webdav/#auth-proxy">rclone auth proxy</a> to authenticate against the built-in radius server of the UDM.
</p>
<h2>Important Notes</h2>
<p>
  <ul>
  <li>Applying changes in UnifiOS of your Unifi Dream Machines (UDM) may lead to loss of warranty.</li>
  <li>No liability for damage or malfunctions of your Dream Machine caused by the installation of this utility.</li>
  <li>Operating a WebDav Server on your UDM and so letting users uploading (big) files can cause the disk storage to run out of space with corresponding consequences for the stability of the entire system (especially if you are using the internal disk as webdav root).</li>
  <li>The default installation creates a 'webdav' WebDav user with default password 'webdav'. Be aware to change the users/passwords under the htpasswd file especially before opening ports of your firewall.</li>
  <li>Upgrading your Dream Machine firmware typically requires to install again.</li>
  <li>WebDav data under the root folder currently is persitent after reboot or even firmware update. But future upgrades could lead to data loss depending on what unifi is changing in the UnifiOS (for critical WebDav data: please backup root folder before update).</li>
  </ul>
</p>
<p>
<b>*** Use it at your own risk! ***</b>
</p>
<p>
Successfully tested on (only one device so far due to lack of hardware):
</p>
<p>
  <table border=1 cellspacing=10>
  <tr>
  <td>Family: UniFi Dream Machine (UDM)</td>
  <td>Model: UniFi Dream Machine Pro (UDM-Pro)</td>
  <td><ul><li>Firmware: 4.0.20</li><li>Firmware: 4.0.21</li><li>Firmware: 4.1.13</li><li>Firmware: 4.2.12</li></ul></td>
  </tr>
  </table>
</p>
<h2>Installation</h2>
<a href="https://help.ui.com/hc/en-us/articles/204909374-UniFi-Connect-with-Debug-Tools-SSH">SSH into your UDM</a> and enter:<br/>&nbsp;<br/>
<code>sudo -v ; curl https://raw.githubusercontent.com/emsi76/unifi_rclone.webdav_radius_auth/refs/heads/main/setup.sh | sudo bash -s -- -i</code>

<h2>Configuration</h2>
2-Step quick config:<br/>&nbsp;<br/>
<ol>
  <li>
    Environment parameters
    <p>
      there are 4 config items under 'rclone_webdav.env' with following defaults:<br/>
      <code># Defining the Port of the Webdav Server
RCLONE_WEBDAV_PORT=55008
# Defining the root folder of the WebDav Server
RCLONE_WEBDAV_ROOT_PATH=/data/rclone_webdav_radius/root
# Defining the path of the log file
RCLONE_WEBDAV_LOG_PATH=/data/rclone_webdav_radius/log.txt
# Definig the location of the SSL Cert
RCLONE_WEBDAV_SSL_CERT=/data/eus_certificates/unifi-os.crt
# Definig the location of the SSL Key
RCLONE_WEBDAV_SSL_KEY=/data/eus_certificates/unifi-os.key
# Definig the radius server port (default 1812)
RCLONE_WEBDAV_RADIUS_PORT=1812
# Definig the radius server secret <mark>mandatory parameter!</mark>
RCLONE_WEBDAV_RADIUS_SECRET=<mark>S3CR3T</mark>
# Definig the (comma separated) list of radius users
# allowed to access webdav server (all radius users allowed if empty)
RCLONE_WEBDAV_RADIUS_USERS=</code>
    </p>
    <p>RCLONE_WEBDAV_RADIUS_SECRET is the only mandatory parameter to set to the secret of your radius config (see <a href="https://help.ui.com/hc/en-us/articles/360015268353-Configuring-a-RADIUS-Server-in-UniFi">unifi radius configuration</a>)</p>
    <p>You can set the path to your disk (ssd/hdd) as RCLONE_WEBDAV_ROOT_PATH if you have a corresponding storage.</p>
    <p>
      To make your changes effective just run the installation commmand again (see <a href="#installation">installation</a> above)!
    </p>
  </li>
  <li>
    User Management
    <p>
      User Management is done via default user management of the radius server (see <a href="https://help.ui.com/hc/en-us/articles/360015268353-Configuring-a-RADIUS-Server-in-UniFi">unifi radius configuration</a>).
      Additionally you can restrict the webdav access to specific radius users only by defining them as list in the environment parameter RCLONE_WEBDAV_RADIUS_USERS above.
    </p>
    <p>
      The user folder of users with failed logins will be banned (renamed with extension "_banned"). To reactivate the access you have to manually rename the folder (via mv command) to the name of the user, so removing the extension "_banned".
    </p>
  </li>
</ol> 
Don't forget to add a firewall rule (or a port forward rule), if you want to access the webdav server from WAN (and read the <a href="#security-considerations">Security considerations</a> before).

<h2>Update</h2>
Same as <a href="#installation">Installation</a> (existing config, htpasswd and root folder won't be touched, remove then manually if you want fresh one).
  
<h2>Use (tested WebDav Clients)</h2>
Connect with your preferred WebDav Client via https to the url/ip of your UDM using the configured port (defaults: 55008).
Depending on the ssl certs you are using on your UDM you will have to trust the cert.<br/>
Following clients were successfully tested:
<p>
  <table border=1 cellspacing=10>
  <tr>
    <th>Client Type</th>
    <th>Client</th>
    <th>App Version(s)</th>
  </tr>
  <tr>
    <td>Browser</td>
    <td><a href="https://www.apple.com/safari/">Safari</a></td>
    <td>18.0.1 (MacOS)</td>
  </tr>
  <tr>
    <td>Browser</td>
    <td><a href="https://www.microsoft.com/en-us/edge/download?form=MA13FJ">Edge</a></td>
    <td>130.0.2849.52 (MacOS)</td>
  </tr>
  <tr>
    <td>App</td>
    <td><a href="https://www.enpass.io">Enpass</a></td>
    <td>6.11.4 (MacOS / iOS)</td>
  </tr> 
  <tr>
    <td>App</td>
    <td><a href="https://subsembly.com/banking4.html">Banking4</a></td>
    <td>8.62 (MacOS / iOS)</td>
  </tr> 
  <tr>
    <td>App</td>
    <td><a href="https://www.photosync-app.com/">PhotoSync</a></td>
    <td>4.9.1 (iOS)</td>
  </tr> 
  </table>
</p>

<h2>Uninstallation</h2>
<p><code>sudo -v ; curl https://raw.githubusercontent.com/emsi76/unifi_rclone.webdav_radius_auth/refs/heads/main/setup.sh | sudo bash -s -- -u</code><br/>
(argument '-u' for uninstallation instead of '-i' for installation)
<br/></p>
<p>
You will have to remove your config files (rclone_webdav_radius.env) as well as default webdav_root folder by yourself with:<br/>&nbsp;
<code>rm -r /data/rclone_webdav_radius</code><br/>
</p>
<p>
If you defined an own WebDav root folder, then also remove manually.
</p>
<h2>Dependencies</h2>
Beside the dependency to <a href="https://github.com/rclone/rclone">rclone</a> the implemented auth_proxy authenticating against the radius server requires freeradius-utils to be installed on the udm, so the proxy can act as radius client.
So, currently the following package will be installed during <a href="#installation">installation</a>:
<ul><li>freeradius-utils=3.2.1+dfsg-3~bpo11+1</li></ul>
<h2>Security considerations</h2>
Rclone uses <a href="https://rclone.org/commands/rclone_serve_webdav/#authentication">http basic authentication</a>. Even additionally secured with https (using the certs of the UDM) the authentication scheme remains poor and is especially unprotected against brute force attacks, because by default endless login failures are allowed. For this reason, this Webdav server is additionally secured via the custom auth_proxy, which bans the user folder when logins fails. The latter makes the server vulnerable for Denial of Service (DoS) for known usernames. It is why you should use non trivial username (like 'admin', 'user', 'guest',...) and do not share the username to third parties. In addition it is also not recommended to connect to this webdav server from public devices as the authentication scheme is also poor in the handling of sessions (no logout). In summary I recommend the <b>following rules to keep secure</b>:<br/>
<ul>
  <li><b>Do not use standard usernames</b> ('admin', 'user', 'guest',...)</li>
  <li><b>Do not connect</b> to this Webdav server <b>from public devices/computers</b>, that are not in your ownership or shared with third parties..</li>
  <li><b>Do not share usernames</b> with third parties.</li>
</ul>
<h2>Tips</h2>
<ul>
  <li>
    Find out the path to your added disk (hdd/sdd) with <b>df -h</b> and check the one with corresponding size:<br/>&nbsp;<br/>
    <img width="50%" height="50%" src="https://github.com/user-attachments/assets/891ed8da-3e4d-43a5-932c-85de825ccb80">
    <br/>In this case: /dev/md3 mounted as /volume1 with 1,7 TB available size is the added Disk, so any folder of /volume1 can be configured as RCLONE_WEBDAV_ROOT_PATH
  </li>
</ul>
<h2>Thanks</h2>
<ul>
<li>to <a href="ui.com">Unifi</a> for the great hardware/firmware accessible via ssh/bash</li>
<li>to <a href="https://github.com/rclone/rclone">rclone</a> for the webdav server software which this utility is based on</li>
<li>to <a href="https://glennr.nl/s/unifi-lets-encrypt">Glenn R. unifi-lets-encrypt</a> making it even possible to run the webdav server with http<b>s</b> and let's encrypt certs of UDM</li>
</ul>
