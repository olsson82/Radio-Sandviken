#!/usr/bin/env bash
LOGINUSR=rs
RUNFOLDER=$(pwd)
VERSIONFILESYS="1.2.3"
#/usr/bin/python3 /home/rs/Systemet/OnAirScreen/start.py
#if [ "$(id -u)" != "0" ]; then
#    echo "You need to run this script as sudo/root."
#    exit 1
#fi

whiptail --title "Radio Sandviken Installation" --msgbox "Välkommen till Radio Sandvikens Installations System för Radio Datorer med Debian 12 Cinnamon. Här inne kan du installera allt som krävs för samtliga datorer samt koppla olika funktioner.\n\nDu kan installera som exempel:\n- Rivendell\n- Jack Audio\n- Jack Mixer\n\nDet är viktigt att du INTE kör detta skript som sudo eller root.\n\nDet mesta är helt automatiskt men det kan förekomma vissa manuella pålägg från din sida.\nTillsammans med detta system ska du ha ett dokument som innehåller alla viktiga uppgifter som du kan behöva fylla i.\n\nDetta system är utvecklat av Andreas Mr Magoo Olsson för Radio Sandviken.\n\nVersion $VERSIONFILESYS" 30 78
LOGINUSR=$(whiptail --title "Användarnamn" --inputbox "Ange användarnamnet som används på denna dator." 8 40 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    if [ -z "$LOGINUSR" ]; then
        exit
    fi
    clear
    sudo_setini() {
        fkey=false
        fsec=false
        tsec=false
        res=""

        if [ -f "$1" ]; then
            while IFS= read -r LINE; do
                TLINE=$(echo $LINE)
                if [[ $TLINE == \[*] ]]; then
                    TLINE=$(echo ${TLINE:1:${#TLINE}-2})
                    if [[ _${TLINE} == _$2 ]]; then
                        tsec=true
                        fsec=true
                    else
                        if $tsec && ! $fkey; then
                            res+=$'\n'$3=$4
                        fi
                        tsec=false
                    fi
                    res+=$'\n'${LINE}
                else
                    TLINE=$(echo ${TLINE%%=*})
                    if $tsec && [[ _${TLINE} == _$3 ]]; then
                        fkey=true
                        res+=$'\n'${LINE%%=*}=$4
                    else
                        res+=$'\n'${LINE}
                    fi
                fi
            done <$1
        fi

        if $tsec && ! $fkey; then
            res+=$'\n'$3=$4
        fi

        if ! $fsec; then
            res+=$'\n'[$2]
            res+=$'\n'$3=$4
        fi
        echo "$res" | sudo tee "$1" >/dev/null
    }

    function addtoSudo {
        if (whiptail --title "Koppla till sudo" --yesno "Detta kommer att lägga till din användare till sudo gruppen, Du måste ange root lösnenordet OK?" 8 78); then
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                su root -c "usermod -a -G sudo $LOGINUSR"
                clear
                whiptail --title "Koppla till sudo" --msgbox "Din användare är nu kopplad till sudo. Vänligen starta om din dator." 15 78
                installloop=0
            done
        else
            clear
        fi

    }
    function connectAudioServer {
        if (whiptail --title "Anslut Musik Server" --yesno "Detta kommer att ansluta ljud server till Rivendell i /var/snd mappen. OK?" 8 78); then
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                AUDSERIP=$(whiptail --title "NAS IP Nummer" --inputbox "Ange ip numret till din NAS" 8 40 3>&1 1>&2 2>&3)
                AUDIOFOLDER=$(whiptail --title "Musik Server Mapp" --inputbox "Ange hela sökvägen till din NFS musik mapp." 8 40 3>&1 1>&2 2>&3)
                sudo apt update &
                sudo apt install curl nfs-common -y
                echo "$AUDSERIP:$AUDIOFOLDER /var/snd nfs nouser,rsize=8192,wsize=8192,atime,auto,rw,dev,exec,suid 0 0" | sudo tee -a /etc/fstab
                sudo systemctl daemon-reload
                sudo mount -all
                clear
                whiptail --title "Anslut Musik Server" --msgbox "Ljudfilerna från din nas är nu kopplade till Rivendell." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function installNowPlayingBosse {
        if (whiptail --title "Installera Nu Spelas Filer" --yesno "Detta kommer installera nödvändiga filer för att Nu Spelas ska fungera. OK?" 8 78); then
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                SHOUTIP=$(whiptail --title "Shoutcast IP Nummer" --inputbox "Ange ip numret till Shoutcast Servern" 8 40 3>&1 1>&2 2>&3)
                SHOUTPASS=$(whiptail --title "Shoutcast Lösenordet" --passwordbox "Ange lösenordet till Shoutcast Servern" 8 40 3>&1 1>&2 2>&3)
                STUDCLOCK=$(whiptail --title "Studio Klocka IP" --inputbox "Ange ip numret till studio klockan" 8 40 3>&1 1>&2 2>&3)
                BRDIP=$(whiptail --title "Broadcast IP" --inputbox "Ange ip numret till broadcast systemets databas" 8 40 3>&1 1>&2 2>&3)
                BRDUSR=$(whiptail --title "Broadcast Användare" --inputbox "Ange användarnamnet till broadcast systemets databas" 8 40 3>&1 1>&2 2>&3)
                BRDPASS=$(whiptail --title "Broadcast Lösenord" --passwordbox "Ange lösenordet till broadcast systemets databas" 8 40 3>&1 1>&2 2>&3)
                BRDDBN=$(whiptail --title "Broadcast Användare" --inputbox "Ange databasnamnet till broadcast systemets databas" 8 40 3>&1 1>&2 2>&3)
                #sudo cp $RUNFOLDER/pypad_bosse.py /usr/lib/rivendell/pypad
                sudo tee -a /usr/lib/rivendell/pypad/pypad_bosse.py >/dev/null <<EOT
#!/usr/bin/python3

# pypad_shoutcast1.py
#
# Write PAD updates to a Shoutcast 1 instance
#
#   (C) Copyright 2018-2020 Fred Gleason <fredg@paravelsystems.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License version 2 as
#   published by the Free Software Foundation.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

import sys
import syslog
import socket
import configparser
import pycurl
import MySQLdb
from datetime import date, datetime
try:
    from rivendellaudio import pypad
except ModuleNotFoundError:
    import pypad  # Rivendell v3.x style
from io import BytesIO


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def ProcessPad(update):
    if update.hasPadType(pypad.TYPE_NOW):
        n = 1
        section = 'Bosse'+str(n)
        while (update.config().has_section(section)):
            #
            # First, get all of our configuration values
            #
            #section = 'Bosse'+str(n)
            #
            # Now, send the update
            #
            if update.shouldBeProcessed(section):
                idet = ""
                prognamn = ""
                contid = ""
                shoutid = ""
                starttid = ""
                stoptid = ""
                man = ""
                tis = ""
                ons = ""
                tor = ""
                fre = ""
                lor = ""
                son = ""
                datenow = "0"
                subtoshout = "0"
                submitokbosse = "0"
                submitokextern = "0"

                db = MySQLdb.connect(
                    host="$BRDIP", user="$BRDUSR", passwd="$BRDPASS", db="$BRDDBN")
                # Get Prog id of enabled
                cur = db.cursor()
                cur.execute(
                    "SELECT id,subtoshout FROM program WHERE conftrans='1' AND enabletrans='1'")
                results = cur.fetchall()
                row_count = cur.rowcount
                cur.close()
                if row_count == 0:
                    # No one is sending so bosse is doing the work
                    submitokbosse = "1"
                    submitokextern = "0"
                else:
                    # Someone is sending but who. Lets check
                    cur = db.cursor()
                    cur.execute(
                        "SELECT id,prognamn,subtoshout FROM program WHERE conftrans='1' AND enabletrans='1'")
                    for row in cur.fetchall():
                        idet = str(row[0])
                        prognamn = str(row[1])
                        subtoshout = str(row[2])
                    cur.close()
                    cur = db.cursor()
                    cur.execute("SELECT id,programid FROM shoutcastapi WHERE programid = %s", (idet,))
                    results = cur.fetchall()
                    row_rakna = cur.rowcount
                    cur.close()
                    if row_rakna == 0:
                        submitokbosse = "0"
                        submitokextern = "1"

                if submitokbosse == "1":
                    # It Exist
                    # Skriv till fil
                    fmtstr = update.config().get(section, 'FormatString')
                    mode = 'w'
                    if update.config().get(section, 'Append') == '1':
                        mode = 'a'
                    f = open(update.resolveFilepath(update.config().get(section, 'Filename'), update.dateTime()), mode) # encoding='cp1252'
                    f.write(update.resolvePadFields(fmtstr, int(update.config().get(section, 'Encoding'))))
                    f.close()
                    #Skicka till klocka
                    #if update.shouldBeProcessed(section):
                    fmtstr=update.config().get(section,'FormatStringUDP')
                    send_sock.sendto(update.resolvePadFields(fmtstr,int(update.config().get(section,'Encoding'))).encode('utf-8'),
                                      (update.config().get(section,'IpAddress'),int(update.config().get(section,'UdpPort'))))
                    #Skicka till Shoutcast
                    try:
                        song = update.escape(update.resolvePadFields(update.config().get(
                        section, 'FormatString'), pypad.ESCAPE_NONE), pypad.ESCAPE_URL)
                        url = 'http://'+update.config().get(section, 'Hostname')+':'+str(update.config().get(section, 'Tcpport'))+'/admin.cgi?pass=' +update.escape(update.config().get(section, 'Password'), pypad.ESCAPE_URL)+'&mode=updinfo&song='+song
                        curl = pycurl.Curl()
                        curl.setopt(curl.URL, url)
                        headers = []
                        headers.append('User-Agent: '+'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.2) Gecko/20070219 Firefox/2.0.0.2')
                        curl.setopt(curl.HTTPHEADER, headers)
                    except configparser.NoSectionError:
                        return
                    try:
                        curl.perform()
                        code = curl.getinfo(pycurl.RESPONSE_CODE)
                        if (code < 200) or (code >= 300):
                            update.syslog(syslog.LOG_WARNING, '['+section+'] returned response code '+str(code))
                    except pycurl.error:
                        update.syslog(syslog.LOG_WARNING,'['+section+'] failed: '+curl.errstr())
                    curl.close()
                if submitokextern == "1":
                    # Skriv till fil
                    fmtstr = update.config().get(section, 'FormatString')
                    mode = 'w'
                    if update.config().get(section, 'Append') == '1':
                        mode = 'a'
                    f = open(update.resolveFilepath(update.config().get(section, 'Filename'), update.dateTime()), mode) # encoding='cp1252'
                    f.write(prognamn)
                    #f.write('Live Program')
                    f.close()
                    #Skriv till Shoutcast
                    #try:
                    #    song = update.escape(update.resolvePadFields(update.config().get(
                    #    section, 'FormatString'), pypad.ESCAPE_NONE), pypad.ESCAPE_URL)
                    #    url = 'http://'+update.config().get(section, 'Hostname')+':'+str(update.config().get(section, 'Tcpport'))+'/admin.cgi?pass=' +update.escape(update.config().get(section, 'Password'), pypad.ESCAPE_URL)+'&mode=updinfo&song='+prognamn
                    #    curl = pycurl.Curl()
                    #    curl.setopt(curl.URL, url)
                    #    headers = []
                    #    headers.append('User-Agent: '+'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.2) Gecko/20070219 Firefox/2.0.0.2')
                    #    curl.setopt(curl.HTTPHEADER, headers)
                    #except configparser.NoSectionError:
                    #    return
                    #try:
                    #    curl.perform()
                    #    code = curl.getinfo(pycurl.RESPONSE_CODE)
                    #    if (code < 200) or (code >= 300):
                    #        update.syslog(syslog.LOG_WARNING, '['+section+'] returned response code '+str(code))
                    #except pycurl.error:
                    #    update.syslog(syslog.LOG_WARNING,'['+section+'] failed: '+curl.errstr())
                    #curl.close()
                    #Skicka till klocka
                    #if update.shouldBeProcessed(section):
                    #fmtstr=update.config().get(section,'FormatStringUDP')
                    #send_sock.sendto(update.resolvePadFields(prognamn,int(update.config().get(section,'Encoding'))).encode('utf-8'),
                    #                  (update.config().get(section,'IpAddress'),int(update.config().get(section,'UdpPort'))))

                # end controlbox
                db.close()

            n = n+1
            section='Bosse'+str(n)


#
# 'Main' function
#
# Create Send Socket
#
send_sock=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
rcvr = pypad.Receiver()
try:
    rcvr.setConfigFile(sys.argv[3])
except IndexError:
    eprint('pypad_shoutcast1.py: USAGE: cmd <hostname> <port> <config>')
    sys.exit(1)
rcvr.setPadCallback(ProcessPad)
rcvr.start(sys.argv[1], int(sys.argv[2]))
EOT
                sudo tee -a /usr/lib/rivendell/pypad/pypad_bosse.exemplar >/dev/null <<EOT
; This is the configuration for the 'pypad_bosse.py' script for 
; Rivendell, which can be used to update the metadata on a Shoutcast
; server using Now & Next data.


; Section Header
;
; One section per Shoutcast server instance is configured, starting with 
; 'Shoutcast1' and working up consecutively
[Bosse1]

; Username
Username=

; Filename
Filename=/mnt/rds/RDS/song.txt

; Append Mode
Append=0

;Encodig
Encoding=0

; Password
Password=$SHOUTPASS

; Host Name
Hostname=$SHOUTIP

; Host Port
Tcpport=4027

; Studio Clock IP
IpAddress=$STUDCLOCK

; Studio Clock UDP port
UdpPort=3310

; Format String.
FormatString=%a - %t

; Format String UDP
FormatStringUDP=NOW:%a - %t\n

; Log Selection
MasterLog=Yes
Aux1Log=Yes
Aux2Log=Yes
VLog101=No
VLog102=No
VLog103=No
VLog104=No
VLog105=No
VLog106=No
VLog107=No
VLog108=No
VLog109=No
VLog110=No
VLog111=No
VLog112=No
VLog113=No
VLog114=No
VLog115=No
VLog116=No
VLog117=No
VLog118=No
VLog119=No
VLog120=No


[NowGroups]
; Group Selection
;
; Filter updates according to the Group membership of the 'now' playing
; event. If no groups are listed here and in the [NextGroups] section,
; then ALL updates will be forwarded
; without regard to Group.
Group1=KRYSSET
Group2=BOSSES
Group3=DANSBANDS
Group4=Inspelning
Group5=CRUSING
Group6=SOMMAR
Group7=SOMMAREN
Group8=JUL
; [...] ; Additional groups can be added...

[NextGroups]
; Group Selection
;
; Filter updates according to the Group membership of the 'next' playing
; event. If no groups are listed here, If no groups are listed here and in
; the [NowGroups] section,then ALL updates will be forwarded
; without regard to Group.
; Group1=MUSIC
; Group2=LEGAL
; [...] ; Additional groups can be added...
EOT
                clear
                whiptail --title "Installera Nu Spelas Filer" --msgbox "Installationen av nu spelas filer är slutförd.\n\nDu kan nu använda dom med rivendell.\nNamnet är pypad_bosse.py" 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function installNowPlayingStudio {
        if (whiptail --title "Installera Nu Spelas Filer" --yesno "Detta kommer installera nödvändiga filer för att Nu Spelas ska fungera. OK?" 8 78); then
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                SHOUTIP=$(whiptail --title "Shoutcast IP Nummer" --inputbox "Ange ip numret till Shoutcast Servern" 8 40 3>&1 1>&2 2>&3)
                SHOUTPASS=$(whiptail --title "Shoutcast Lösenordet" --passwordbox "Ange lösenordet till Shoutcast Servern" 8 40 3>&1 1>&2 2>&3)
                STUDCLOCK=$(whiptail --title "Studio Klocka IP" --inputbox "Ange ip numret till studio klockan" 8 40 3>&1 1>&2 2>&3)
                BRDIP=$(whiptail --title "Broadcast IP" --inputbox "Ange ip numret till broadcast systemets databas" 8 40 3>&1 1>&2 2>&3)
                BRDUSR=$(whiptail --title "Broadcast Användare" --inputbox "Ange användarnamnet till broadcast systemets databas" 8 40 3>&1 1>&2 2>&3)
                BRDPASS=$(whiptail --title "Broadcast Lösenord" --passwordbox "Ange lösenordet till broadcast systemets databas" 8 40 3>&1 1>&2 2>&3)
                BRDDBN=$(whiptail --title "Broadcast Användare" --inputbox "Ange databasnamnet till broadcast systemets databas" 8 40 3>&1 1>&2 2>&3)
                #sudo cp $RUNFOLDER/pypad_bosse.py /usr/lib/rivendell/pypad
                sudo tee -a /usr/lib/rivendell/pypad/pypad_studio.exemplar >/dev/null <<EOT
; This is the sample configuration for the 'pypad_studio.py' script for 
; Rivendell, which can be used to update the metadata on a Shoutcast
; server using Now & Next data.


; Section Header
;
; One section per Shoutcast server instance is configured, starting with 
; 'Shoutcast1' and working up consecutively
[Studio1]

; Username
Username=

; Filename
;Filename=/mnt/latar/song.txt
Filename=/mnt/rds/RDS/song.txt
; Append Mode
Append=0

;Encodig
Encoding=0

; Password
Password=$SHOUTPASS

; Host Name
Hostname=$SHOUTIP

; Host Port
Tcpport=4027

; Studio Clock IP
IpAddress=$STUDCLOCK

; Studio Clock UDP port
UdpPort=3310

; Format String.
FormatString=%a - %t

; Format String UDP
FormatStringUDP=NOW:%a - %t\n

; Log Selection
MasterLog=Yes
Aux1Log=Yes
Aux2Log=Yes
VLog101=No
VLog102=No
VLog103=No
VLog104=No
VLog105=No
VLog106=No
VLog107=No
VLog108=No
VLog109=No
VLog110=No
VLog111=No
VLog112=No
VLog113=No
VLog114=No
VLog115=No
VLog116=No
VLog117=No
VLog118=No
VLog119=No
VLog120=No


[NowGroups]
; Group Selection
;
; Filter updates according to the Group membership of the 'now' playing
; event. If no groups are listed here and in the [NextGroups] section,
; then ALL updates will be forwarded
; without regard to Group.
Group1=BOSSES
Group2=DANSBAND
Group3=DANSJUL
Group4=JUL
Group5=SOMMAR
Group6=DANSBANDS
; [...] ; Additional groups can be added...

[NextGroups]
; Group Selection
;
; Filter updates according to the Group membership of the 'next' playing
; event. If no groups are listed here, If no groups are listed here and in
; the [NowGroups] section,then ALL updates will be forwarded
; without regard to Group.
; Group1=MUSIC
; Group2=LEGAL
; [...] ; Additional groups can be added...
EOT
                sudo tee -a /usr/lib/rivendell/pypad/pypad_studio.py >/dev/null <<EOT
#!/usr/bin/python3

# pypad_studio.py
#
# Write PAD updates to a Shoutcast 1 instance
#
#   (C) Copyright 2018-2020 Fred Gleason <fredg@paravelsystems.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License version 2 as
#   published by the Free Software Foundation.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

import sys
import syslog
import socket
import configparser
import pycurl
import MySQLdb
from datetime import date, datetime
try:
    from rivendellaudio import pypad
except ModuleNotFoundError:
    import pypad
from io import BytesIO


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def ProcessPad(update):
    if update.hasPadType(pypad.TYPE_NOW):
        n = 1
        section = 'Studio'+str(n)
        while (update.config().has_section(section)):
            #
            # First, get all of our configuration values
            #            
            try:
                song = update.escape(update.resolvePadFields(update.config().get(section, 'FormatString'), pypad.ESCAPE_NONE), pypad.ESCAPE_URL)
                url = 'http://'+update.config().get(section, 'Hostname')+':'+str(update.config().get(section, 'Tcpport'))+'/admin.cgi?pass=' +update.escape(update.config().get(section, 'Password'), pypad.ESCAPE_URL)+'&mode=updinfo&song='+song
                curl = pycurl.Curl()
                curl.setopt(curl.URL, url)
                headers = []
                #
                # D.N.A.S v1.9.8 refuses to process updates with the default
                # CURL user-agent value, hence we lie to it.
                #
                headers.append(
                    'User-Agent: '+'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.2) Gecko/20070219 Firefox/2.0.0.2')
                curl.setopt(curl.HTTPHEADER, headers)
            except configparser.NoSectionError:
                return

            #
            # Now, send the update
            #
            if update.shouldBeProcessed(section):
                idet = ""
                subtoshout = ""
                contid = ""
                shoutid = ""

                db = MySQLdb.connect(
                    host="$BRDIP", user="$BRDUSR", passwd="$BRDPASS", db="$BRDDBN")
                # Get Prog id of enabled
                cur = db.cursor()
                cur.execute(
                    "SELECT id,subtoshout FROM program WHERE conftrans='1' AND enabletrans='1'")
                for row in cur.fetchall():
                    idet = str(row[0])
                    subtoshout = str(row[1])
                cur.close()
                # Stop get prog id
                # Get controlbox
                cur = db.cursor()
                cur.execute(
                    "SELECT id FROM controlbox WHERE program = %s AND extbox = %s", (idet, '1'))
                results = cur.fetchall()
                row_count = cur.rowcount
                if row_count > 0:
                    cura = db.cursor()
                    cura.execute(
                        "SELECT id FROM shoutcastapi WHERE programid = %s AND isbosse = %s", (idet, '0'))
                    results2 = cura.fetchall()
                    row_count2 = cura.rowcount
                    if row_count2 > 0:
                        # It Exist
                        fmtstr = update.config().get(section, 'FormatString')
                        mode = 'w'
                        if update.config().get(section, 'Append') == '1':
                            mode = 'a'
                        f = open(update.resolveFilepath(update.config().get(section, 'Filename'), update.dateTime()), mode)
                        f.write(update.resolvePadFields(fmtstr, int(update.config().get(section, 'Encoding'))))
                        f.close()
                        # Till klocka
                        fmtstr=update.config().get(section,'FormatStringUDP')
                        send_sock.sendto(update.resolvePadFields(fmtstr,int(update.config().get(section,'Encoding'))).encode('utf-8'),
                                         (update.config().get(section,'IpAddress'),int(update.config().get(section,'UdpPort'))))
                        try:
                            curl.perform()
                            code = curl.getinfo(pycurl.RESPONSE_CODE)
                            if (code < 200) or (code >= 300):
                                update.syslog(syslog.LOG_WARNING, '['+section+'] returned response code '+str(code))
                        except pycurl.error:
                            update.syslog(syslog.LOG_WARNING,'['+section+'] failed: '+curl.errstr())
                        curl.close()
                    cura.close()

                cur.close()
                # end controlbox
                db.close()

            n = n+1
            section='Studio'+str(n)


#
# 'Main' function
#
send_sock=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
rcvr = pypad.Receiver()
try:
    rcvr.setConfigFile(sys.argv[3])
except IndexError:
    eprint('pypad_shoutcast1.py: USAGE: cmd <hostname> <port> <config>')
    sys.exit(1)
rcvr.setPadCallback(ProcessPad)
rcvr.start(sys.argv[1], int(sys.argv[2]))
EOT
                clear
                whiptail --title "Installera Nu Spelas Filer" --msgbox "Installationen av nu spelas filer är slutförd.\n\nDu kan nu använda dom med rivendell.\nNamnet är pypad_studio.py" 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function connectReferens {
        if (whiptail --title "Anslut Referens Nas" --yesno "Detta kommer att ansluta referens nas till din master computer. OK?" 8 78); then
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                REFSERIP=$(whiptail --title "NAS IP Nummer" --inputbox "Ange ip nummer till din NAS" 8 40 3>&1 1>&2 2>&3)
                REFFOLDER=$(whiptail --title "Referens Mapp" --inputbox "Ange namnet på referens mappen i din NAS med hela sökvägen." 8 40 3>&1 1>&2 2>&3)
                sudo apt update &
                sudo apt install curl nfs-common -y
                sudo mkdir /mnt/rds
                sudo chmod 777 /mnt/rds
                echo "$REFSERIP:$REFFOLDER /mnt/rds nfs nouser,rsize=8192,wsize=8192,atime,auto,rw,dev,exec,suid 0 0" | sudo tee -a /etc/fstab
                sudo systemctl daemon-reload
                sudo mount -all
                clear
                whiptail --title "Anslut Referens Nas" --msgbox "Refrens mappen är nu kopplad till datorn." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function connectReferensStudio {
        if (whiptail --title "Koppla nu spelas mapp" --yesno "Detta kommer att koppla mapp för låt titlarna ska kunna visas. OK?" 8 78); then
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                REFSERIP=$(whiptail --title "NAS IP Nummer" --inputbox "Ange ip nummer till din NAS" 8 40 3>&1 1>&2 2>&3)
                REFFOLDER=$(whiptail --title "Referens Mapp" --inputbox "Ange namnet på referens mappen i din NAS med hela sökvägen." 8 40 3>&1 1>&2 2>&3)
                sudo apt update &
                sudo apt install curl nfs-common -y
                sudo mkdir /mnt/rds
                sudo chmod 777 /mnt/rds
                echo "$REFSERIP:$REFFOLDER /mnt/rds nfs nouser,rsize=8192,wsize=8192,atime,auto,rw,dev,exec,suid 0 0" | sudo tee -a /etc/fstab
                sudo systemctl daemon-reload
                sudo mount -all
                clear
                whiptail --title "Koppla nu spelas mapp" --msgbox "Mappen är nu kopplad för att låt titlarna ska kunna visas på Shoutcast och i RDS." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function addLogGenerator {
        if (whiptail --title "Auto Logg Generator" --yesno "Detta kommer att lägga till Automatisk logg generator för Master Datorn. OK?" 8 78); then
            clear
            whiptail --title "Auto Logg Generator" --msgbox "Du kommer att bli förfrågad att ange Master Service namn. Detta är Rivendells Service för Master Datorn\n\nNormalt är det namnet Master." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                MASTERSERVICE=$(whiptail --title "Master Service" --inputbox "Ange namnet på Master Servicen" 8 40 3>&1 1>&2 2>&3)
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                tee -a /home/$LOGINUSR/Systemet/generatelog.sh >/dev/null <<EOT
#!/bin/dash

/usr/bin/rdlogmanager -g -s $MASTERSERVICE -d 0
EOT
                chmod u+x /home/$LOGINUSR/Systemet/generatelog.sh
                cronjob="0 4 * * * /home/$LOGINUSR/Systemet/generatelog.sh"
                (
                    crontab -u $LOGINUSR -l
                    echo "$cronjob"
                ) | crontab -u $LOGINUSR -
                clear
                whiptail --title "Auto Logg Generator" --msgbox "Auto Logg Generatorn är nu skapad för Master datorn, och kommer att köras under natten." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function installResetScript {
        if (whiptail --title "Installera återställning skript" --yesno "Detta kommer installera återställnings skript. OK?" 8 78); then
            clear
            whiptail --title "Installera återställning skript" --msgbox "Återställnings skriptet ser till så allt är startat och om Rivendell skulle crasha så startas allt om automatiskt." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                sudo apt install curl silentjack -y
                tee -a /home/$LOGINUSR/Systemet/reset.sh >/dev/null <<EOT
#!/bin/bash
curl -s \
    --form-string "token=axx9rfjd86c9j5yioq82zhnntrqfyu" \
    --form-string "user=gysjckjhoijezf1w2eca9opsgkbg2m" \
    --form-string "message=Bosse Startas om!!" \
    https://api.pushover.net/1/messages.json
echo "Meddelat personalen"
cp /tmp/rlm_filewrite.txt /home/$LOGINUSR/Systemet/kolla/musik_\$(date -Is).txt
echo "Sparat musiken i kolla"
killall rdairplay
echo "Stoppat RDAirplay"
killall qjackctl
echo "Stoppat qjackctl"
pkill -f /usr/bin/jack_mixer
echo "Stoppat Jack Mixer"
cd /home/$LOGINUSR/Systemet
sudo systemctl restart rivendell.service
echo "Rivendell Omstart"
sleep 10
/usr/bin/qjackctl &
echo "Ljudkoppling Omstart"
sleep 5
/bin/bash /home/$LOGINUSR/Systemet/ljudkort.sh 1>/dev/null 2>&1
echo "Ljudkort Omstart"
sleep 5
/usr/bin/jack_mixer -c /home/$LOGINUSR/Systemet/mixer.xml &
echo "Mixer Omstart"
sleep 5
/usr/bin/rdairplay &
echo "RDAirplay Omstart"
sleep 45
rmlsend PN\ "1"! &
echo "Startat Musiken"
sleep 2
rmlsend PN\ "1"\ "2"! &
echo "Startat Andra"
sleep 10
silentjack -p 20 -g 600 -c jack_mixer:Rivendell\ Out\ L -n varning ./terminal.sh
EOT
                chmod u+x /home/$LOGINUSR/Systemet/reset.sh
                tee -a /home/$LOGINUSR/Systemet/terminal.sh >/dev/null <<EOT
#!/bin/sh
#pkill -f reset.sh
gnome-terminal --working-directory /home/$LOGINUSR/Systemet -- ./reset.sh
EOT
                chmod u+x /home/$LOGINUSR/Systemet/terminal.sh
                clear
                whiptail --title "Installera återställning skript" --msgbox "Återställnings skriptet är nu installerat. Detta kan starta vid uppstart av datorn." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function installJackMixerFaders {

        if (whiptail --title "Installera Jack Mixer faders" --yesno "Detta kommer skapa mixer fil i Systemet mappen. OK?" 8 78); then
            clear
            whiptail --title "Installera Jack Mixer faders" --msgbox "Faders filen som kommer installeras behövs för att Master datorn ska fungera korrekt.\n\nVi skapar mixer.xml fil som startas med Jack Mixer." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                tee -a /home/$LOGINUSR/Systemet/mixer.xml >/dev/null <<EOT
<?xml version="1.0" ?>
<jack_mixer geometry="420x420" paned_position="210" visible="True">
	<input_channel name="Rivendell" type="stereo" direct_output="True" volume="13.783784" balance="0.000000" wide="True" meter_prefader="False" out_mute="False" volume_midi_cc="11" balance_midi_cc="12" mute_midi_cc="13" solo_midi_cc="14"/>
	<gui_factory confirm-quit="False" default_meter_scale="K20" default_project_path="" default_slider_scale="linear_30dB" midi_behavior_mode="0" use_custom_widgets="False" vumeter_color="#ccb300" vumeter_color_scheme="default" auto_reset_peak_meters="False" auto_reset_peak_meters_time_seconds="2.0" meter_refresh_period_milliseconds="33"/>
</jack_mixer>
EOT
                clear
                whiptail --title "Installera Jack Mixer faders" --msgbox "Filen mixer.xml är nu installerad i Systemet mappen." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function setupQJackCtl {

        if (whiptail --title "Ställ in QjackCtl" --yesno "Detta kommer ställa in QjackCtl. Se till så det är avstängt & installerat innan du kör denna funktion. OK?" 8 78); then
            clear
            whiptail --title "Ställ in QjackCtl" --msgbox "QJackCtl är programmet för att sköta ljudkopplingar så alla kopplingar kommer dit dom ska.\nHär kommer vi ställa in allt som behövs för att det ska fungera." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                killall qjackctl
                LJUDKORTSNAMN=$(whiptail --title "Ljudkorts namnet" --inputbox "Namnet på vad ljudkortet heter" 8 40 3>&1 1>&2 2>&3)
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                tee /home/$LOGINUSR/Systemet/ljudkoppling.xml >/dev/null <<EOT
<!DOCTYPE patchbay>
<patchbay version="0.9.9" name="ljudkoppling">
 <output-sockets>
  <socket client="rivendell_0" type="jack-audio" exclusive="off" name="rivendell_ 1">
   <plug>playout_0L</plug>
   <plug>playout_0R</plug>
  </socket>
  <socket client="jack_mixer" type="jack-audio" exclusive="off" name="jack_mixer 1">
   <plug>Rivendell\ Out\ L</plug>
   <plug>Rivendell\ Out\ R</plug>
  </socket>
 </output-sockets>
 <input-sockets>
  <socket client="jack_mixer" type="jack-audio" exclusive="off" name="jack_mixer 1">
   <plug>Rivendell\ L</plug>
   <plug>Rivendell\ R</plug>
  </socket>
  <socket client="$LJUDKORTSNAMN\ Ut" type="jack-audio" exclusive="off" name="$LJUDKORTSNAMN\ Ut 1">
   <plug>playback_1</plug>
   <plug>playback_2</plug>
  </socket>
 </input-sockets>
 <slots/>
 <cables>
  <cable input="jack_mixer 1" output="rivendell_ 1" type="jack-audio"/>
  <cable input="$LJUDKORTSNAMN\ Ut 1" output="jack_mixer 1" type="jack-audio"/>
 </cables>
</patchbay>

EOT
                tee /home/$LOGINUSR/.config/rncbc.org/QjackCtl.conf >/dev/null <<EOT
[Defaults]
ConnectionsTabPage=0
MessagesStatusTabPage=0
PatchbayPath=/home/$LOGINUSR/Systemet/ljudkoppling.xml
SessionSaveVersion=true

[Geometry]
qjackctlConnectionsForm\geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\0\0\0\0\x14\0\0\x1\xdf\0\0\x1S\0\0\0\0\0\0\0\x14\0\0\x1\xdf\0\0\x1S\0\0\0\0\0\0\0\0\a\x80\0\0\0\0\0\0\0\x14\0\0\x1\xdf\0\0\x1S)
qjackctlConnectionsForm\visible=false
qjackctlGraphForm\geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\xbe\0\0\0\x8f\0\0\x6\xc3\0\0\x3\xe7\0\0\0\xbe\0\0\0\x8f\0\0\x6\xc3\0\0\x3\xe7\0\0\0\0\0\0\0\0\a\x80\0\0\0\xbe\0\0\0\x8f\0\0\x6\xc3\0\0\x3\xe7)
qjackctlGraphForm\visible=false
qjackctlMainForm\geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0_\0\0\0%\0\0\x2!\0\0\0\x8a\0\0\0_\0\0\0%\0\0\x2!\0\0\0\x8a\0\0\0\0\0\0\0\0\a\x80\0\0\0_\0\0\0%\0\0\x2!\0\0\0\x8a)
qjackctlMainForm\visible=false
qjackctlMessagesStatusForm\geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\0\0\0\0\x14\0\0\x1\xdf\0\0\x1S\0\0\0\0\0\0\0\x14\0\0\x1\xdf\0\0\x1S\0\0\0\0\0\0\0\0\a\x80\0\0\0\0\0\0\0\x14\0\0\x1\xdf\0\0\x1S)
qjackctlMessagesStatusForm\visible=false
qjackctlPatchbayForm\geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\x32\0\0\0W\0\0\x2\xb8\0\0\x1\x96\0\0\0\x32\0\0\0W\0\0\x2\xb8\0\0\x1\x96\0\0\0\0\0\0\0\0\a\x80\0\0\0\x32\0\0\0W\0\0\x2\xb8\0\0\x1\x96)
qjackctlPatchbayForm\visible=false
qjackctlSessionForm\geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\0\0\0\0\x14\0\0\x1\xdf\0\0\x1S\0\0\0\0\0\0\0\x14\0\0\x1\xdf\0\0\x1S\0\0\0\0\0\0\0\0\a\x80\0\0\0\0\0\0\0\x14\0\0\x1\xdf\0\0\x1S)
qjackctlSessionForm\visible=false

[GraphCanvas]
CanvasRect=@Variant(\0\0\0\x14\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0)
CanvasZoom=1

[GraphColors]
0x2c2fdc12=#6b006b
0x30fc78a9=#6b0000
0x888db5ec=#6b6b00
0xae9f46b4=#006b6b
0xb91441cf=#006b00

[GraphLayout]
qjackctlGraphForm=@ByteArray(\0\0\0\xff\0\0\0\0\xfd\0\0\0\0\0\0\x6\x6\0\0\x3\x1\0\0\0\x4\0\0\0\x4\0\0\0\b\0\0\0\b\xfc\0\0\0\x1\0\0\0\x2\0\0\0\x1\0\0\0\xe\0T\0o\0o\0l\0\x42\0\x61\0r\x1\0\0\0\0\xff\xff\xff\xff\0\0\0\0\0\0\0\0)

[GraphNodePos]
14%3AMidi%20Through%3AInput=@Variant(\0\0\0\x1a@n\x80\0\0\0\0\0\xc0\`\x80\0\0\0\0\0)
14%3AMidi%20Through%3AOutput=@Variant(\0\0\0\x1a\xc0q@\0\0\0\0\0\xc0\x61\0\0\0\0\0\0)
Ljud%20In=@Variant(\0\0\0\x1a\xc0o\xe0\0\0\0\0\0@d\xe0\0\0\0\0\0)
Ljud%20Ut=@Variant(\0\0\0\x1a@\x84P\0\0\0\0\0@^\x80\0\0\0\0\0)
jack_mixer=@Variant(\0\0\0\x1a@i\xa0\0\0\0\0\0@d\0\0\0\0\0\0)
rivendell_0=@Variant(\0\0\0\x1a\xc0<\0\0\0\0\0\0\xc0\x34\0\0\0\0\0\0)
system%3AInput=@Variant(\0\0\0\x1a@n\x80\0\0\0\0\0@J\0\0\0\0\0\0)
system%3AOutput=@Variant(\0\0\0\x1a\xc0r@\0\0\0\0\0@D\0\0\0\0\0\0)
varning=@Variant(\0\0\0\x1a\xc0 \0\0\0\0\0\0\xc0 \0\0\0\0\0\0)

[GraphView]
ConnectThroughNodes=false
Menubar=true
RepelOverlappingNodes=false
SortOrder=0
SortType=0
Statusbar=true
TextBesideIcons=true
Toolbar=true
ZoomRange=false

[History]
ActivePatchbayPathComboBox\Item1=/home/$LOGINUSR/Systemet/ljudkoppling.xml
MessagesLogPathComboBox\Item1=qjackctl.log
ServerConfigNameComboBox\Item1=.jackdrc
ServerNameComboBox\Item1=(default)
ServerPrefixComboBox\Item1=jackd
ServerPrefixComboBox\Item2=jackdmp
ServerPrefixComboBox\Item3=jackstart
XrunRegexComboBox\Item1=xrun of at least ([0-9|\\.]+) msecs

[Options]
ActivePatchbay=true
ActivePatchbayPath=/home/$LOGINUSR/Systemet/ljudkoppling.xml
ActivePatchbayReset=false
AliasesEditing=false
AliasesEnabled=false
AlsaSeqEnabled=true
BaseFontSize=0
ConnectionsFont="Sans Serif,10,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
ConnectionsIconSize=0
CustomColorTheme=
CustomStyleTheme=
DBusEnabled=false
DisplayBlink=true
DisplayEffect=true
DisplayFont1="Sans Serif,12,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
DisplayFont2="Sans Serif,6,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
GraphButton=true
JackClientPortAlias=0
JackClientPortMetadata=false
JackDBusEnabled=false
KeepOnTop=false
LeftButtons=true
MessagesFont="Monospace,8,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
MessagesLimit=true
MessagesLimitLines=1000
MessagesLog=false
MessagesLogPath=qjackctl.log
PostShutdownScript=false
PostShutdownScriptShell=
PostStartupScript=false
PostStartupScriptShell=
QueryClose=false
QueryDisconnect=true
QueryRestart=false
QueryShutdown=true
RightButtons=true
ServerConfig=true
ServerConfigName=.jackdrc
ShutdownScript=false
ShutdownScriptShell=
Singleton=true
StartJack=false
StartMinimized=true
StartupScript=false
StartupScriptShell=
StdoutCapture=true
StopJack=false
SystemTray=true
SystemTrayQueryClose=false
TextLabels=true
TimeDisplay=0
TransportButtons=true
XrunRegex=xrun of at least ([0-9|\\.]+) msecs

[Patchbays]
Patchbay1=/home/$LOGINUSR/Systemet/ljudkoppling.xml

[Presets]
DefPreset=(default)
OldPreset=

[Program]
Version=0.9.9

[Splitter]
AlsaConnectView\sizes=38, 20, 38
AudioConnectView\sizes=269, 90, 269
InfraClientSplitter\sizes=13, 13
MidiConnectView\sizes=38, 20, 38
PatchbayView\sizes=38, 20, 38
EOT
                clear
                whiptail --title "Ställ in QjackCtl" --msgbox "Allt som behövs för QJackCtl är nu inställt. Du kan nu starta QJackCtl igen." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function addAutostartMaster {

        if (whiptail --title "Lägg till uppstarts program" --yesno "Vill du lägga till uppstarts program? OK?" 8 78); then
            clear
            whiptail --title "Lägg till uppstarts program" --msgbox "Vi kommer att lägga till dom programmen som behöver starta vid inloggning åt dig för Master Datorn." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                if [ -d "/home/$LOGINUSR/.config/autostart" ]; then
                    cd /home/$LOGINUSR/.config/autostart
                else
                    mkdir /home/$LOGINUSR/.config/autostart
                    cd /home/$LOGINUSR/.config/autostart
                fi
                tee -a /home/$LOGINUSR/.config/autostart/Uppstartsprogram.desktop >/dev/null <<EOT
[Desktop Entry]
Type=Application
Exec=/home/$LOGINUSR/Systemet/reset.sh
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
Name[sv_SE]=Uppstartsprogram
Comment[sv_SE]=Program som behöver laddas på Master Datorn
X-GNOME-Autostart-Delay=10
EOT
                clear
                whiptail --title "Lägg till uppstarts program" --msgbox "Vi har nu lagt in det som behövs på Master Datorn vid inloggning." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function forMasterComputer {
        while true; do
            CHOICES=$(
                whiptail --title "Välj vad du vill göra" --menu "Välj här vad du vill göra på Master Datorn" 20 100 10 \
                    "1)" "Skapa auto logg generator" \
                    "2)" "Installera återställnings skript" \
                    "3)" "Installera Jack Mixer faders" \
                    "4)" "Koppla referens mapp" \
                    "5)" "Installera skript för Nu Spelas" \
                    "6)" "Ställ in QJackCtl" \
                    "7)" "Installera Rivendell Web Broadcast" \
                    "8)" "Lägg till uppstarts program" \
                    "9)" "Hjälp och Information" \
                    "10)" "Gå tillbaka" 3>&2 2>&1 1>&3
            )
            result=$(whoami)
            case $CHOICES in
            "1)")
                addLogGenerator
                ;;
            "2)")
                installResetScript
                ;;
            "3)")
                installJackMixerFaders
                ;;
            "4)")
                connectReferens
                ;;
            "5)")
                installNowPlayingBosse
                ;;
            "6)")
                setupQJackCtl
                ;;
            "7)")
                installRivWeb
                ;;
            "8)")
                addAutostartMaster
                ;;
            "9)")
                MasterHelp
                ;;
            "10)")
                break
                ;;
            esac
            #whiptail --msgbox "$result" 20 78
        done
    }

    function MasterHelp {
        whiptail --textbox --scrolltext $RUNFOLDER/masterhelp.txt 20 80
    }

    function StudioHelp {
        whiptail --textbox --scrolltext $RUNFOLDER/studiohelp.txt 20 80
    }

    function ProcessHelp {
        whiptail --textbox --scrolltext $RUNFOLDER/processhelp.txt 20 80
    }

    function ClockHelp {
        whiptail --textbox --scrolltext $RUNFOLDER/clockhelp.txt 20 80
    }

    function addAutostartClock {

        if (whiptail --title "Lägg till uppstarts program" --yesno "Vill du lägga till uppstarts program? OK?" 8 78); then
            clear
            whiptail --title "Lägg till uppstarts program" --msgbox "Vi kommer att lägga till dom programmen som behöver starta vid inloggning åt dig för Klock Datorn." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                if [ -d "/home/$LOGINUSR/.config/autostart" ]; then
                    cd /home/$LOGINUSR/.config/autostart
                else
                    mkdir /home/$LOGINUSR/.config/autostart
                    cd /home/$LOGINUSR/.config/autostart
                fi
                tee -a /home/$LOGINUSR/.config/autostart/OnAirScreen.desktop >/dev/null <<EOT
[Desktop Entry]
Type=Application
Exec=/usr/bin/python3 /home/$LOGINUSR/Systemet/OnAirScreen/start.py
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
Name[sv_SE]=OnAirScreen
Comment[sv_SE]=Laddar studio klocka
X-GNOME-Autostart-Delay=15
EOT
                clear
                whiptail --title "Lägg till uppstarts program" --msgbox "Vi har nu lagt in det som behövs på Master Datorn vid inloggning." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function forClockComputer {
        while true; do
            CHOICES=$(
                whiptail --title "Välj vad du vill göra" --menu "Välj här vad du vill göra på Klock Datorn" 16 100 9 \
                    "1)" "Installera OnAirScreen" \
                    "2)" "Lägg till uppstarts program" \
                    "3)" "Hjälp & Information" \
                    "9)" "Gå tillbaka" 3>&2 2>&1 1>&3
            )
            result=$(whoami)
            case $CHOICES in
            "1)")
                installClock
                ;;
            "2)")
                addAutostartClock
                ;;
            "3)")
                ClockHelp
                ;;
            "9)")
                break
                ;;
            esac
            #whiptail --msgbox "$result" 20 78
        done
    }

    function setupQJackCtlStudio {

        if (whiptail --title "Ställ in QjackCtl" --yesno "Detta kommer ställa in QjackCtl. Se till så det är avstängt & installerat innan du kör denna funktion. OK?" 8 78); then
            clear
            whiptail --title "Ställ in QjackCtl" --msgbox "QJackCtl är programmet för att sköta ljudkopplingar så alla kopplingar kommer dit dom ska.\nHär kommer vi ställa in allt som behövs för att det ska fungera." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                killall qjackctl
                LJUDKORTSNAMN=$(whiptail --title "Ljudkorts namnet" --inputbox "Namnet på vad ljudkortet heter" 8 40 3>&1 1>&2 2>&3)
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                tee /home/$LOGINUSR/Systemet/ljudkoppling.xml >/dev/null <<EOT
<!DOCTYPE patchbay>
<patchbay version="0.9.9" name="ljudkoppling">
 <output-sockets>
  <socket exclusive="off" client="rivendell_0" type="jack-audio" name="rivendell_ 4">
   <plug>playout_3L</plug>
   <plug>playout_3R</plug>
  </socket>
  <socket exclusive="off" client="$LJUDKORTSNAMN\ In" type="jack-audio" name="$LJUDKORTSNAMN\ In 1">
   <plug>capture_3</plug>
   <plug>capture_4</plug>
  </socket>
  <socket exclusive="off" client="PulseAudio\ JACK\ Sink" type="jack-audio" name="PulseAudio\ JACK\ Sink 1">
   <plug>front\-left</plug>
   <plug>front\-right</plug>
  </socket>
  <socket exclusive="off" client="$LJUDKORTSNAMN" type="alsa-midi" name="$LJUDKORTSNAMN 1">
   <plug>$LJUDKORTSNAMN\ MIDI\ 1</plug>
  </socket>
  <socket exclusive="off" client="$LJUDKORTSNAMN" type="alsa-midi" name="$LJUDKORTSNAMN 2">
   <plug>$LJUDKORTSNAMN\ MIDI\ 2</plug>
  </socket>
  <socket exclusive="off" client="$LJUDKORTSNAMN" type="alsa-midi" name="$LJUDKORTSNAMN 3">
   <plug>$LJUDKORTSNAMN\ MIDI\ 3</plug>
  </socket>
  <socket exclusive="off" client="$LJUDKORTSNAMN" type="alsa-midi" name="$LJUDKORTSNAMN 4">
   <plug>$LJUDKORTSNAMN\ MIDI\ 4</plug>
  </socket>
  <socket exclusive="off" client="Mixxx" type="jack-audio" name="Mixxx 1">
   <plug>out_24</plug>
   <plug>out_25</plug>
  </socket>
  <socket exclusive="off" client="Mixxx" type="jack-audio" name="Mixxx 2">
   <plug>out_26</plug>
   <plug>out_27</plug>
  </socket>
  <socket exclusive="off" client="Mixxx" type="jack-audio" name="Mixxx 3">
   <plug>out_28</plug>
   <plug>out_29</plug>
  </socket>
  <socket exclusive="on" client="Mixxx" type="jack-audio" name="Mixxx 4">
   <plug>out_30</plug>
  </socket>
  <socket exclusive="off" client="rivendell_0" type="jack-audio" name="rivendell_ 1">
   <plug>playout_0L</plug>
   <plug>playout_0R</plug>
  </socket>
  <socket exclusive="off" client="rivendell_0" type="jack-audio" name="rivendell_ 2">
   <plug>playout_1L</plug>
   <plug>playout_1R</plug>
  </socket>
  <socket exclusive="off" client="rivendell_0" type="jack-audio" name="rivendell_ 3">
   <plug>playout_2L</plug>
   <plug>playout_2R</plug>
  </socket>
 </output-sockets>
 <input-sockets>
  <socket exclusive="off" client="$LJUDKORTSNAMN\ Ut" type="jack-audio" name="$LJUDKORTSNAMN\ Ut 9">
   <plug>playback_19</plug>
   <plug>playback_20</plug>
  </socket>
  <socket exclusive="off" client="rivendell_0" type="jack-audio" name="rivendell_ 1">
   <plug>record_1L</plug>
   <plug>record_1R</plug>
  </socket>
  <socket exclusive="off" client="Arduino\ Leonardo" type="alsa-midi" name="Arduino\ Leonardo 1">
   <plug>Arduino\ Leonardo\ MIDI\ 1</plug>
  </socket>
  <socket exclusive="on" client="$LJUDKORTSNAMN\ Ut" type="jack-audio" name="$LJUDKORTSNAMN\ Ut 8">
   <plug>playback_15</plug>
   <plug>playback_16</plug>
  </socket>
  <socket exclusive="on" client="$LJUDKORTSNAMN\ Ut" type="jack-audio" name="$LJUDKORTSNAMN\ Ut 4">
   <plug>playback_7</plug>
   <plug>playback_8</plug>
  </socket>
  <socket exclusive="on" client="$LJUDKORTSNAMN\ Ut" type="jack-audio" name="$LJUDKORTSNAMN\ Ut 5">
   <plug>playback_9</plug>
   <plug>playback_10</plug>
  </socket>
  <socket exclusive="on" client="$LJUDKORTSNAMN\ Ut" type="jack-audio" name="$LJUDKORTSNAMN\ Ut 6">
   <plug>playback_11</plug>
   <plug>playback_12</plug>
  </socket>
  <socket exclusive="on" client="$LJUDKORTSNAMN\ Ut" type="jack-audio" name="$LJUDKORTSNAMN\ Ut 7">
   <plug>playback_13</plug>
   <plug>playback_14</plug>
  </socket>
  <socket exclusive="on" client="$LJUDKORTSNAMN\ Ut" type="jack-audio" name="$LJUDKORTSNAMN\ Ut 1">
   <plug>playback_17</plug>
   <plug>playback_18</plug>
  </socket>
  <socket exclusive="on" client="$LJUDKORTSNAMN\ Ut" type="jack-audio" name="$LJUDKORTSNAMN\ Ut 2">
   <plug>playback_3</plug>
   <plug>playback_4</plug>
  </socket>
  <socket exclusive="on" client="$LJUDKORTSNAMN\ Ut" type="jack-audio" name="$LJUDKORTSNAMN\ Ut 3">
   <plug>playback_5</plug>
   <plug>playback_6</plug>
  </socket>
 </input-sockets>
 <slots/>
 <cables>
  <cable output="PulseAudio\ JACK\ Sink 1" type="jack-audio" input="$LJUDKORTSNAMN\ Ut 8"/>
  <cable output="$LJUDKORTSNAMN 1" type="alsa-midi" input="Arduino\ Leonardo 1"/>
  <cable output="$LJUDKORTSNAMN 2" type="alsa-midi" input="Arduino\ Leonardo 1"/>
  <cable output="$LJUDKORTSNAMN 3" type="alsa-midi" input="Arduino\ Leonardo 1"/>
  <cable output="$LJUDKORTSNAMN 4" type="alsa-midi" input="Arduino\ Leonardo 1"/>
  <cable output="Mixxx 1" type="jack-audio" input="$LJUDKORTSNAMN\ Ut 4"/>
  <cable output="Mixxx 2" type="jack-audio" input="$LJUDKORTSNAMN\ Ut 5"/>
  <cable output="Mixxx 3" type="jack-audio" input="$LJUDKORTSNAMN\ Ut 6"/>
  <cable output="Mixxx 4" type="jack-audio" input="$LJUDKORTSNAMN\ Ut 7"/>
  <cable output="rivendell_ 1" type="jack-audio" input="$LJUDKORTSNAMN\ Ut 1"/>
  <cable output="rivendell_ 2" type="jack-audio" input="$LJUDKORTSNAMN\ Ut 2"/>
  <cable output="rivendell_ 3" type="jack-audio" input="$LJUDKORTSNAMN\ Ut 3"/>
  <cable output="rivendell_ 4" type="jack-audio" input="$LJUDKORTSNAMN\ Ut 9"/>
  <cable output="$LJUDKORTSNAMN\ In 1" type="jack-audio" input="rivendell_ 1"/>
 </cables>
</patchbay>


EOT
                tee /home/$LOGINUSR/.config/rncbc.org/QjackCtl.conf >/dev/null <<EOT
[Defaults]
ConnectionsTabPage=0
MessagesStatusTabPage=0
PatchbayPath=/home/$LOGINUSR/Systemet/ljudkoppling.xml
SessionSaveVersion=true

[Geometry]
qjackctlGraphForm\geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\x1@\0\0\0\xe9\0\0\a\xbd\0\0\x5\x34\0\0\x1@\0\0\0\xe9\0\0\a\xbd\0\0\x5\x34\0\0\0\0\0\0\0\0\rp\0\0\x1@\0\0\0\xe9\0\0\a\xbd\0\0\x5\x34)
qjackctlGraphForm\visible=false
qjackctlMainForm\geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\x5\r\0\0\x1\x65\0\0\x6\xcf\0\0\x1\xc8\0\0\x5\r\0\0\x1\x65\0\0\x6\xcf\0\0\x1\xc8\0\0\0\0\0\0\0\0\rp\0\0\x5\r\0\0\x1\x65\0\0\x6\xcf\0\0\x1\xc8)
qjackctlMainForm\visible=false
qjackctlPatchbayForm\geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\xd0\0\0\0\x8b\0\0\x3V\0\0\x1\xca\0\0\0\xd0\0\0\0\x8b\0\0\x3V\0\0\x1\xca\0\0\0\0\0\0\0\0\rp\0\0\0\xd0\0\0\0\x8b\0\0\x3V\0\0\x1\xca)
qjackctlPatchbayForm\visible=false

[GraphCanvas]
CanvasRect="@Variant(\0\0\0\x14\xc0\x85,\0\0\0\0\0\xc0\x63\x10\0\0\0\0\0@\xa0\x16\0\0\0\0\0@\x92\b\0\0\0\0\0)"
CanvasZoom=1

[GraphColors]
0x2c2fdc12=#6b006b
0x30fc78a9=#6b0000
0x888db5ec=#6b6b00
0xae9f46b4=#006b6b
0xb91441cf=#006b00

[GraphLayout]
qjackctlGraphForm=@ByteArray(\0\0\0\xff\0\0\0\0\xfd\0\0\0\0\0\0\x6~\0\0\x3\xf4\0\0\0\x4\0\0\0\x4\0\0\0\b\0\0\0\b\xfc\0\0\0\x1\0\0\0\x2\0\0\0\x1\0\0\0\xe\0T\0o\0o\0l\0\x42\0\x61\0r\x1\0\0\0\0\xff\xff\xff\xff\0\0\0\0\0\0\0\0)

[GraphNodePos]
14%3AMidi%20Through%3AInput=@Variant(\0\0\0\x1a@p\x80\0\0\0\0\0\xc0\x63\0\0\0\0\0\0)
14%3AMidi%20Through%3AOutput=@Variant(\0\0\0\x1a\xc0q\xc0\0\0\0\0\0\xc0\x62\x80\0\0\0\0\0)
16%3AWING%3AInput=@Variant(\0\0\0\x1a@\x94t\0\0\0\0\0@\x18\0\0\0\0\0\0)
16%3AWING%3AOutput=@Variant(\0\0\0\x1a\xc0u\x80\0\0\0\0\0@\x84 \0\0\0\0\0)
24%3AWING%3AInput=@Variant(\0\0\0\x1a@p\x80\0\0\0\0\0@g\x80\0\0\0\0\0)
24%3AWING%3AOutput=@Variant(\0\0\0\x1a\xc0q\x80\0\0\0\0\0@f\0\0\0\0\0\0)
28%3AArduino%20Leonardo%3AInput=@Variant(\0\0\0\x1a@p\x80\0\0\0\0\0@P\0\0\0\0\0\0)
28%3AArduino%20Leonardo%3AOutput=@Variant(\0\0\0\x1a\xc0q\0\0\0\0\0\0@B\0\0\0\0\0\0)
Mixxx=@Variant(\0\0\0\x1a\xc0i@\0\0\0\0\0@^\x80\0\0\0\0\0)
PortAudio=@Variant(\0\0\0\x1a@q\x80\0\0\0\0\0@n\x80\0\0\0\0\0)
PulseAudio%20JACK%20Sink=@Variant(\0\0\0\x1a\xc0uP\0\0\0\0\0@~\x10\0\0\0\0\0)
PulseAudio%20JACK%20Source=@Variant(\0\0\0\x1a@\x80\0\0\0\0\0\0@\x85\xf0\0\0\0\0\0)
Wing%20In=@Variant(\0\0\0\x1a\xc0\x83H\0\0\0\0\0\xc0V\x80\0\0\0\0\0)
Wing%20Ut=@Variant(\0\0\0\x1a@\x8a\xa0\0\0\0\0\0\xc0_\0\0\0\0\0\0)
rivendell_0=@Variant(\0\0\0\x1a@6\0\0\0\0\0\0\xc0[@\0\0\0\0\0)
system%3AInput=@Variant(\0\0\0\x1a@r0\0\0\0\0\0@\x83@\0\0\0\0\0)
system%3AOutput=@Variant(\0\0\0\x1a\xc0\\\x80\0\0\0\0\0@\x87\xe8\0\0\0\0\0)

[GraphView]
ConnectThroughNodes=false
Menubar=true
RepelOverlappingNodes=false
SortOrder=0
SortType=0
Statusbar=true
TextBesideIcons=true
Toolbar=true
ZoomRange=false

[History]
ActivePatchbayPathComboBox\Item1=/home/$LOGINUSR/Systemet/ljudkoppling.xml
MessagesLogPathComboBox\Item1=qjackctl.log
ServerConfigNameComboBox\Item1=.jackdrc
ServerNameComboBox\Item1=(default)
ServerPrefixComboBox\Item1=jackd
ServerPrefixComboBox\Item2=jackdmp
ServerPrefixComboBox\Item3=jackstart
XrunRegexComboBox\Item1=xrun of at least ([0-9|\\.]+) msecs

[Options]
ActivePatchbay=true
ActivePatchbayPath=/home/$LOGINUSR/Systemet/ljudkoppling.xml
ActivePatchbayReset=false
AliasesEditing=false
AliasesEnabled=false
AlsaSeqEnabled=true
BaseFontSize=0
ConnectionsFont="Sans Serif,10,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
ConnectionsIconSize=0
CustomColorTheme=
CustomStyleTheme=
DBusEnabled=false
DisplayBlink=true
DisplayEffect=true
DisplayFont1="Sans Serif,12,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
DisplayFont2="Sans Serif,6,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
GraphButton=true
JackClientPortAlias=0
JackClientPortMetadata=false
JackDBusEnabled=false
KeepOnTop=false
LeftButtons=true
MessagesFont="Monospace,8,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
MessagesLimit=true
MessagesLimitLines=1000
MessagesLog=false
MessagesLogPath=qjackctl.log
PostShutdownScript=false
PostShutdownScriptShell=
PostStartupScript=false
PostStartupScriptShell=
QueryClose=true
QueryDisconnect=true
QueryRestart=false
QueryShutdown=true
RightButtons=true
ServerConfig=true
ServerConfigName=.jackdrc
ShutdownScript=false
ShutdownScriptShell=
Singleton=true
StartJack=false
StartMinimized=true
StartupScript=false
StartupScriptShell=
StdoutCapture=true
StopJack=false
SystemTray=true
SystemTrayQueryClose=false
TextLabels=true
TimeDisplay=0
TransportButtons=true
XrunRegex=xrun of at least ([0-9|\\.]+) msecs

[Patchbays]
Patchbay1=/home/$LOGINUSR/Systemet/ljudkoppling.xml

[Presets]
DefPreset=(default)
OldPreset=

[Program]
Version=0.9.9

[Settings]
Audio=0
Chan=0
ClockSource=0
Dither=0
Driver=alsa
Frames=0
HWMeter=false
IgnoreHW=false
InChannels=0
InDevice=
InLatency=0
Interface=
MidiDriver=raw
Monitor=false
NoMemLock=false
OutChannels=0
OutDevice=
OutLatency=0
Periods=1
PortMax=0
Priority=5
Realtime=true
SampleRate=0
SelfConnectMode=32
Server=jackd
ServerName=
ServerSuffix=
Shorts=false
SoftMode=false
StartDelay=2
Sync=false
Timeout=0
UnlockMem=false
Verbose=false
Wait=0
WordLength=0

[Splitter]
PatchbayView\sizes=386, 65, 386
EOT
                clear
                whiptail --title "Ställ in QjackCtl" --msgbox "Allt som behövs för QJackCtl är nu inställt. Du kan nu starta QJackCtl igen." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function setupAudacity {

        if (whiptail --title "Ställ in Audacity" --yesno "Detta kommer ställa in Audacity. Se till så det är avstängt & startat en gång. OK?" 8 78); then
            clear
            whiptail --title "Ställ in Audacity" --msgbox "Vi kommer ställa in Audacity så vi får rätt kopplingar till rätt ljud ingång och utgång." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                killall qjackctl
                LJUDKORTSNAMN=$(whiptail --title "Ljudkorts namnet" --inputbox "Namnet på vad ljudkortet heter" 8 40 3>&1 1>&2 2>&3)
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                tee /home/$LOGINUSR/.config/audacity/audacity.cfg >/dev/null <<EOT
PrefsVersion=1.1.1r1
MenuBar=File,Edit,Select,View,Transport,Tracks,Generate,Effect,Analyze,Tools,Optional,Help,HiddenFileItems
AudioTimeFormat=hh:mm:ss
Importers=AUP,PCM,OGG,FLAC,MP3,LOF,WavPack,FFmpeg
Preferences=Device,Playback,Recording,MidiIO,Quality,GUI,Tracks,ImportExport,Library,Directories,Warnings,Effects,KeyConfig,Mouse,Module
[GUI]
[GUI/ToolBars]
[GUI/ToolBars/Tools]
MultiToolActive=0
DockV2=1
Dock=1
Path=0,0
Show=1
X=-1
Y=-1
W=66
H=55
[GUI/ToolBars/Control]
DockV2=1
Dock=1
Path=0
Show=1
X=-1
Y=-1
W=385
H=55
[GUI/ToolBars/CombinedMeter]
DockV2=1
Dock=0
Show=0
X=-1
Y=-1
W=338
H=27
[GUI/ToolBars/RecordMeter]
DockV2=1
Dock=1
Path=0,0,0,0,0
Show=1
X=-1
Y=-1
W=290
H=27
[GUI/ToolBars/PlayMeter]
DockV2=1
Dock=1
Path=0,0,0,0,0,0
Show=1
X=-1
Y=-1
W=290
H=27
[GUI/ToolBars/Edit]
DockV2=1
Dock=1
Path=0,0,0
Show=1
X=-1
Y=-1
W=150
H=55
[GUI/ToolBars/Transcription]
DockV2=2
Dock=2
Path=0,0,0
Show=1
X=-1
Y=-1
W=191
H=27
[GUI/ToolBars/Scrub]
DockV2=1
Dock=0
Show=0
X=-1
Y=-1
W=92
H=27
[GUI/ToolBars/Device]
DockV2=1
Dock=0
Show=0
X=-1
Y=-1
W=883
H=27
[GUI/ToolBars/Selection]
DockV2=2
Dock=2
Path=0
Show=1
X=-1
Y=-1
W=598
H=55
[GUI/ToolBars/SpectralSelection]
DockV2=2
Dock=0
Show=0
X=-1
Y=-1
W=230
H=55
[GUI/ToolBars/Audio\ Setup]
DockV2=1
Dock=1
Path=0,0,0,0
Show=1
X=-1
Y=-1
W=83
H=55
[GUI/ToolBars/Time]
DockV2=2
Dock=2
Path=0,0
Show=1
X=-1
Y=-1
W=250
H=55
[GUI/ToolBars/CutCopyPaste]
DockV2=1
Dock=0
Show=0
X=-1
Y=-1
W=66
H=55
[Version]
Major=3
Minor=2
Micro=4
[Directories]
TempDir=/var/tmp/audacity-rs
[Module]
mod-script-pipe=4
[ModulePath]
mod-script-pipe=/usr/lib/audacity/modules/mod-script-pipe.so
[ModuleDateTime]
mod-script-pipe=2023-02-01T21:56:51
[AudioIO]
RecordingDevice=$LJUDKORTSNAMN In
Host=JACK Audio Connection Kit
PlaybackDevice=$LJUDKORTSNAMN Ut
RecordChannels=2
RecordingSourceIndex=-1
RecordingSource=
PlaybackSource=
[SamplingRate]
DefaultProjectSampleRate=48000
[MenuBar]
[MenuBar/Optional]
[MenuBar/Optional/Extra]
Part1=Transport,Tools,Mixer,Edit,PlayAtSpeed,Seek,Device,Select
Part2=Navigation,Focus,Cursor,Track,Scriptables1,Scriptables2,Misc
[MenuBar/Optional/Extra/Part1]
Transport=Play,Stop,PlayOneSec,PlayToSelection,PlayBeforeSelectionStart,PlayAfterSelectionStart,PlayBeforeSelectionEnd,PlayAfterSelectionEnd,PlayBeforeAndAfterSelectionStart,PlayBeforeAndAfterSelectionEnd,PlayCutPreview,KeyboardScrubbing
Edit=DeleteKey,DeleteKey2,TimeShift
Select=SnapToOff,SnapToNearest,SnapToPrior,SelStart,SelEnd,SelExtLeft,SelExtRight,SelSetExtLeft,SelSetExtRight,SelCntrLeft,SelCntrRight,MoveToLabel
[MenuBar/View]
Windows=UndoHistory,Karaoke,MixerBoard
Other=Toolbars,ShowExtraMenus,ShowTrackNameInWaveform,ShowClipping
[MenuBar/View/Other]
[MenuBar/View/Other/Toolbars]
[MenuBar/View/Other/Toolbars/Toolbars]
Other=ShowTransportTB,ShowToolsTB,ShowRecordMeterTB,ShowPlayMeterTB,ShowEditTB,ShowCutCopyPasteTB,ShowTranscriptionTB,ShowScrubbingTB,ShowDeviceTB,ShowSelectionTB,ShowTimeTB,ShowSpectralSelectionTB,ShowAudioSetupTB
[MenuBar/Analyze]
[MenuBar/Analyze/Analyzers]
Windows=ContrastAnalyser,PlotSpectrum
[MenuBar/Transport]
Basic=Play,Record,Scrubbing,Cursor
[MenuBar/Transport/Basic]
Cursor=CursSelStart,CursSelEnd,CursTrackStart,CursTrackEnd,Clip,CursProjectStart,CursProjectEnd
[MenuBar/Tracks]
[MenuBar/Tracks/Add]
Add=NewMonoTrack,NewStereoTrack,NewLabelTrack,NewTimeTrack
[MenuBar/Edit]
Other=Clip,LabelEditMenus,EditMetaData,RenameClip
[MenuBar/Select]
Basic=SelectAll,SelectNone,Tracks,Region,Spectral,Clip
[MenuBar/Help]
[MenuBar/Help/Other]
Diagnostics=DeviceInfo,MidiDeviceInfo,Log,CrashReport
[FFmpeg]
Enabled=1
[Preferences]
Tracks=TracksBehaviors,Spectrum
ImportExport=ExtImport
[Prefs]
Width=775
Height=489
[Window]
X=398
Y=229
Width=1120
Height=906
Maximized=0
Normal_X=398
Normal_Y=229
Normal_Width=1120
Normal_Height=906
Iconized=0
EOT
                clear
                whiptail --title "Ställ in Audacity" --msgbox "Allt som behövs för Audacity är nu inställt." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function setupMixxx {

        if (whiptail --title "Ställ in Mixxx" --yesno "Detta kommer ställa in Mixxx. Se till så det är avstängt & startat en gång. OK?" 8 78); then
            clear
            whiptail --title "Ställ in Mixxx" --msgbox "Vi kommer ställa in Mixxx så vi får rätt kopplingar till rätt ljud ingång och utgång.\n\nVi kommer även se till så regelstarten fungerar som den ska." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                LJUDKORTSNAMN=$(whiptail --title "Ljudkorts namnet" --inputbox "Namnet på vad ljudkortet heter" 8 40 3>&1 1>&2 2>&3)
                BROADCASTIP=$(whiptail --title "Broadcast IP Nummer" --inputbox "Ange ip numret till Broadcast Servern" 8 40 3>&1 1>&2 2>&3)
                SHOUTIP=$(whiptail --title "Shoutcast IP Nummer" --inputbox "Ange ip numret till Shoutcast Servern" 8 40 3>&1 1>&2 2>&3)
                SHOUTPASS=$(whiptail --title "Shoutcast Lösenordet" --passwordbox "Ange lösenordet till Shoutcast Servern" 8 40 3>&1 1>&2 2>&3)
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                FILEN=/home/$LOGINUSR/Systemet/mixxxplay.sh
                echo "#!/usr/bin/env bash" | tee -a $FILEN >/dev/null
                echo "UPDATEVALUE=1" | tee -a $FILEN >/dev/null
                echo "touch /home/$LOGINUSR/Systemet/nowplaying.txt-prev /home/$LOGINUSR/Systemet/nowplaying.txt" | tee -a $FILEN >/dev/null
                echo "while true; do" | tee -a $FILEN >/dev/null
                echo "    art=\$(sqlite3 /home/$LOGINUSR/.mixxx/mixxxdb.sqlite 'select library.artist from library where library.id = (select PlaylistTracks.track_id from PlaylistTracks where id = (select max(id) from PlaylistTracks));')" | tee -a $FILEN >/dev/null
                echo "    tit=\$(sqlite3 /home/$LOGINUSR/.mixxx/mixxxdb.sqlite 'select library.title from library where library.id = (select PlaylistTracks.track_id from PlaylistTracks where id = (select max(id) from PlaylistTracks));')" | tee -a $FILEN >/dev/null
                echo '    songtext="$art - $tit"' | tee -a $FILEN >/dev/null
                echo "    tee /home/$LOGINUSR/Systemet/nowplaying.txt >/dev/null <<EOT" | tee -a $FILEN >/dev/null
                echo "\$art - \$tit" | tee -a $FILEN >/dev/null
                echo "EOT" | tee -a $FILEN >/dev/null
                echo "    if ! diff /home/$LOGINUSR/Systemet/nowplaying.txt /home/$LOGINUSR/Systemet/nowplaying.txt-prev >/dev/null; then" | tee -a $FILEN >/dev/null
                echo "        SONGUPDATE=\"\$(curl --silent "http://$BROADCASTIP/api/mixxx.php" | jq -r .isok)\"" | tee -a $FILEN >/dev/null
                echo '        if [ "$SONGUPDATE" == "$UPDATEVALUE" ]; then' | tee -a $FILEN >/dev/null
                echo "            \$(curl --silent \"http://$SHOUTIP:4027/admin.cgi?pass=$SHOUTPASS&mode=updinfo&song=\$songtext\")" | tee -a $FILEN >/dev/null
                echo '            tee /mnt/rds/RDS/song.txt >/dev/null <<EOT' | tee -a $FILEN >/dev/null
                echo '$art - $tit' | tee -a $FILEN >/dev/null
                echo 'EOT' | tee -a $FILEN >/dev/null
                echo '        fi' | tee -a $FILEN >/dev/null
                echo '        echo track has changed' | tee -a $FILEN >/dev/null
                echo "        cat /home/$LOGINUSR/Systemet/nowplaying.txt" | tee -a $FILEN >/dev/null
                echo "        cp /home/$LOGINUSR/Systemet/nowplaying.txt /home/$LOGINUSR/Systemet/nowplaying.txt-prev" | tee -a $FILEN >/dev/null
                echo '    fi' | tee -a $FILEN >/dev/null
                echo '    sleep 10' | tee -a $FILEN >/dev/null
                echo 'done' | tee -a $FILEN >/dev/null
                chmod u+x $FILEN
                mkdir /home/$LOGINUSR/.mixxx/controllers
                tee /home/$LOGINUSR/.mixxx/controllers/Regelstart.midi.xml >/dev/null <<EOT
<?xml version='1.0' encoding='utf-8'?>
<MixxxControllerPreset mixxxVersion="" schemaVersion="1">
    <info>
        <name>Regelstart</name>
    </info>
    <controller id="">
        <scriptfiles/>
        <controls>
            <control>
                <group>[Channel1]</group>
                <key>play</key>
                <description>MIDI Learned from 34 messages.</description>
                <status>0x90</status>
                <midino>0x30</midino>
                <options>
                    <normal/>
                </options>
            </control>
            <control>
                <group>[Channel2]</group>
                <key>play</key>
                <description>MIDI Learned from 1 messages.</description>
                <status>0x90</status>
                <midino>0x31</midino>
                <options>
                    <normal/>
                </options>
            </control>
            <control>
                <group>[Channel3]</group>
                <key>play</key>
                <description>MIDI Learned from 1 messages.</description>
                <status>0x90</status>
                <midino>0x32</midino>
                <options>
                    <normal/>
                </options>
            </control>
            <control>
                <group>[Channel4]</group>
                <key>play</key>
                <description>MIDI Learned from 27 messages.</description>
                <status>0x90</status>
                <midino>0x33</midino>
                <options>
                    <normal/>
                </options>
            </control>
        </controls>
        <outputs/>
    </controller>
</MixxxControllerPreset>
EOT
                tee /home/$LOGINUSR/.mixxx/soundconfig.xml >/dev/null <<EOT
<!DOCTYPE SoundManagerConfig>
<SoundManagerConfig samplerate="48000" force_network_clock="0" latency="5" deck_count="4" api="JACK Audio Connection Kit" sync_buffers="2">
 <SoundDevice name="$LJUDKORTSNAMN Ut" portAudioIndex="13">
  <output channel="12" channel_count="2" index="3" type="Deck"/>
  <output channel="10" channel_count="2" index="2" type="Deck"/>
  <output channel="8" channel_count="2" index="1" type="Deck"/>
  <output channel="6" channel_count="2" index="0" type="Deck"/>
 </SoundDevice>
</SoundManagerConfig>
EOT
                tee /home/$LOGINUSR/.mixxx/mixxx.cfg >/dev/null <<EOT

[Auto DJ]
EnableRandomQueue 0
EnableRandomQueueBuff 0
IgnoreTime 23:59
MinimumAvailable 20
RandomQueueMinimumAllowed 5
Requeue 0
Transition 10
UseIgnoreTime 0

[BPM]
BPMDetectionEnabled 1
BeatDetectionFixedTempoAssumption 1
FastAnalysisEnabled 0
ReanalyzeImported 0
ReanalyzeWhenSettingsChange 0

[Channel1]
keylock 0
quantize 0
vinylcontrol_enabled 0
vinylcontrol_lead_in_time 0
vinylcontrol_speed_type 33.3 RPM
vinylcontrol_vinyl_type Serato CV02 Vinyl, Side A

[Channel2]
keylock 0
quantize 0
vinylcontrol_enabled 0
vinylcontrol_lead_in_time 0
vinylcontrol_speed_type 33.3 RPM
vinylcontrol_vinyl_type Serato CV02 Vinyl, Side A

[Channel3]
keylock 0
quantize 0
vinylcontrol_enabled 0
vinylcontrol_lead_in_time 0
vinylcontrol_speed_type 33.3 RPM
vinylcontrol_vinyl_type Serato CV02 Vinyl, Side A

[Channel4]
keylock 0
quantize 0
vinylcontrol_enabled 0
vinylcontrol_lead_in_time 0
vinylcontrol_speed_type 33.3 RPM
vinylcontrol_vinyl_type Serato CV02 Vinyl, Side A

[Config]
HotcueColorPalette Mixxx Hotcue Colors
InhibitScreensaver 1
Locale 
Path /usr/share/mixxx/
ResizableSkin LateNight
ScaleFactor 1
ScaleFactorAuto 0
Scheme PaleMoon
StartInFullscreen 0
TrackColorPalette Mixxx Track Colors
Version 2.3.3

[ControllerPreset]
Arduino_Leonardo_MIDI_1 /home/$LOGINUSR/.mixxx/controllers/Regelstart.midi.xml

[Controller]
Arduino_Leonardo_MIDI_1 1

[Controls]
AllowTrackLoadToPlayingDeck 0
CloneDeckOnLoadDoubleTap 1
CueDefault 0
CueRecall 3
HotcueDefaultColorIndex 8
PositionDisplay 2
RateDir 1
RatePermLeft 0.5
RatePermRight 0.05
RateRamp 0
RateRampSensitivity 250
RateRangePercent 8
RateTempLeft 4
RateTempRight 2
SetIntroStartAtMainCue 1
SpeedAutoReset 1
TimeFormat 0
Tooltips 1
auto_hotcue_colors 0
keylockMode 0
keyunlockMode 0

[EffectRack1]
show 1

[EffectRack1_EffectUnit1]
focused_effect 0
group_[Auxiliary1]_enable 0
group_[Auxiliary2]_enable 0
group_[Auxiliary3]_enable 0
group_[Auxiliary4]_enable 0
group_[BusCenter]_enable 0
group_[BusLeft]_enable 0
group_[BusRight]_enable 0
group_[BusTalkover]_enable 0
group_[Channel1]_enable 1
group_[Channel2]_enable 0
group_[Channel3]_enable 0
group_[Channel4]_enable 0
group_[Headphone]_enable 0
group_[MasterOutput]_enable 0
group_[Master]_enable 0
group_[Microphone2]_enable 0
group_[Microphone3]_enable 0
group_[Microphone4]_enable 0
group_[Microphone]_enable 0
group_[PreviewDeck1]_enable 0
group_[Sampler10]_enable 0
group_[Sampler11]_enable 0
group_[Sampler12]_enable 0
group_[Sampler13]_enable 0
group_[Sampler14]_enable 0
group_[Sampler15]_enable 0
group_[Sampler16]_enable 0
group_[Sampler1]_enable 0
group_[Sampler2]_enable 0
group_[Sampler3]_enable 0
group_[Sampler4]_enable 0
group_[Sampler5]_enable 0
group_[Sampler6]_enable 0
group_[Sampler7]_enable 0
group_[Sampler8]_enable 0
group_[Sampler9]_enable 0
mix 1
show_parameters 0

[EffectRack1_EffectUnit2]
focused_effect 0
group_[Auxiliary1]_enable 0
group_[Auxiliary2]_enable 0
group_[Auxiliary3]_enable 0
group_[Auxiliary4]_enable 0
group_[BusCenter]_enable 0
group_[BusLeft]_enable 0
group_[BusRight]_enable 0
group_[BusTalkover]_enable 0
group_[Channel1]_enable 0
group_[Channel2]_enable 1
group_[Channel3]_enable 0
group_[Channel4]_enable 0
group_[Headphone]_enable 0
group_[MasterOutput]_enable 0
group_[Master]_enable 0
group_[Microphone2]_enable 0
group_[Microphone3]_enable 0
group_[Microphone4]_enable 0
group_[Microphone]_enable 0
group_[PreviewDeck1]_enable 0
group_[Sampler10]_enable 0
group_[Sampler11]_enable 0
group_[Sampler12]_enable 0
group_[Sampler13]_enable 0
group_[Sampler14]_enable 0
group_[Sampler15]_enable 0
group_[Sampler16]_enable 0
group_[Sampler1]_enable 0
group_[Sampler2]_enable 0
group_[Sampler3]_enable 0
group_[Sampler4]_enable 0
group_[Sampler5]_enable 0
group_[Sampler6]_enable 0
group_[Sampler7]_enable 0
group_[Sampler8]_enable 0
group_[Sampler9]_enable 0
mix 1
show_parameters 0

[EffectRack1_EffectUnit3]
focused_effect 0
group_[Auxiliary1]_enable 0
group_[Auxiliary2]_enable 0
group_[Auxiliary3]_enable 0
group_[Auxiliary4]_enable 0
group_[BusCenter]_enable 0
group_[BusLeft]_enable 0
group_[BusRight]_enable 0
group_[BusTalkover]_enable 0
group_[Channel1]_enable 0
group_[Channel2]_enable 0
group_[Channel3]_enable 1
group_[Channel4]_enable 0
group_[Headphone]_enable 0
group_[MasterOutput]_enable 0
group_[Master]_enable 0
group_[Microphone2]_enable 0
group_[Microphone3]_enable 0
group_[Microphone4]_enable 0
group_[Microphone]_enable 0
group_[PreviewDeck1]_enable 0
group_[Sampler10]_enable 0
group_[Sampler11]_enable 0
group_[Sampler12]_enable 0
group_[Sampler13]_enable 0
group_[Sampler14]_enable 0
group_[Sampler15]_enable 0
group_[Sampler16]_enable 0
group_[Sampler1]_enable 0
group_[Sampler2]_enable 0
group_[Sampler3]_enable 0
group_[Sampler4]_enable 0
group_[Sampler5]_enable 0
group_[Sampler6]_enable 0
group_[Sampler7]_enable 0
group_[Sampler8]_enable 0
group_[Sampler9]_enable 0
mix 1
show_parameters 0

[EffectRack1_EffectUnit4]
focused_effect 0
group_[Auxiliary1]_enable 0
group_[Auxiliary2]_enable 0
group_[Auxiliary3]_enable 0
group_[Auxiliary4]_enable 0
group_[BusCenter]_enable 0
group_[BusLeft]_enable 0
group_[BusRight]_enable 0
group_[BusTalkover]_enable 0
group_[Channel1]_enable 0
group_[Channel2]_enable 0
group_[Channel3]_enable 0
group_[Channel4]_enable 1
group_[Headphone]_enable 0
group_[MasterOutput]_enable 0
group_[Master]_enable 0
group_[Microphone2]_enable 0
group_[Microphone3]_enable 0
group_[Microphone4]_enable 0
group_[Microphone]_enable 0
group_[PreviewDeck1]_enable 0
group_[Sampler10]_enable 0
group_[Sampler11]_enable 0
group_[Sampler12]_enable 0
group_[Sampler13]_enable 0
group_[Sampler14]_enable 0
group_[Sampler15]_enable 0
group_[Sampler16]_enable 0
group_[Sampler1]_enable 0
group_[Sampler2]_enable 0
group_[Sampler3]_enable 0
group_[Sampler4]_enable 0
group_[Sampler5]_enable 0
group_[Sampler6]_enable 0
group_[Sampler7]_enable 0
group_[Sampler8]_enable 0
group_[Sampler9]_enable 0
mix 1
show_parameters 0

[Effects]
AdoptMetaknobValue 1

[EqualizerRack1_[Channel1]]
focused_effect 0
group_[Channel1]_enable 1
mix 1
show_parameters 0

[EqualizerRack1_[Channel2]]
focused_effect 0
group_[Channel2]_enable 1
mix 1
show_parameters 0

[EqualizerRack1_[Channel3]]
focused_effect 0
group_[Channel3]_enable 1
mix 1
show_parameters 0

[EqualizerRack1_[Channel4]]
focused_effect 0
group_[Channel4]_enable 1
mix 1
show_parameters 0

[InternalClock]
bpm 122

[Key]
FastAnalysisEnabled 0
KeyDetectionEnabled 1
KeyNotation Traditional
ReanalyzeWhenSettingsChange 0

[Keyboard]
Enabled 1

[LateNight]
deck_size_without_mixer 1
expand_samplers_1-4 0
expand_samplers_1-8 0
expand_samplers_9-16 0
max_lib_show_decks 1
sampler_rows 1
show_loopjump_controls_compact 0
show_spinny_cover 1
show_sync_button_compact 0
show_vumeters_compact 1

[Library]
EditMetadataSelectedClick 0
EnableWaveformCaching 1
EnableWaveformGenerationWithAnalysis 1
RescanOnStartup 0
SeratoMetadataExport 0
ShowBansheeLibrary 1
ShowITunesLibrary 1
ShowRekordboxLibrary 1
ShowRhythmboxLibrary 1
ShowSeratoLibrary 1
ShowTraktorLibrary 1
SupportedFileExtensions 3g2,3gp,aac,aif,aiff,caf,flac,it,m4a,m4v,med,mj2,mod,mov,mp3,mp4,ogg,okt,opus,s3m,stm,wav,wv,xm
SyncTrackMetadataExport 0
TrackLoadAction 0
UseRelativePathOnExport 0
show_coverart 1

[MainWindow]
geometry AdnQywADAAAAAA1wAAAAAAAAFO8AAASvAAANcAAAACUAABTvAAAErwAAAAECAAAAB4AAAA1wAAAAJQAAFO8AAASv
state AAAA/wAAAAD9AAAAAAAAB4AAAAR1AAAABAAAAAQAAAAIAAAACPwAAAAA

[Master]
boothDelay 0
delay 0
duckMode 1
duckStrength 90
enabled 1
headDelay 0
keylock_engine 1
microphoneLatencyCompensation 0
mono_mixdown 0
show_mixer 1
talkover_mix 0

[Microphone]
show_microphone 0

[Mixer Profile]
EQsOnly yes
EffectForGroup_[Channel1] org.mixxx.effects.biquadfullkilleq
EffectForGroup_[Channel2] org.mixxx.effects.biquadfullkilleq
EffectForGroup_[Channel3] org.mixxx.effects.biquadfullkilleq
EffectForGroup_[Channel4] org.mixxx.effects.biquadfullkilleq
EffectForGroup_[Master] 
EqAutoReset 0
GainAutoReset 0
HiEQFrequency 2484
HiEQFrequencyPrecise 2484.999990
LoEQFrequency 246
LoEQFrequencyPrecise 246.469196
QuickEffectForGroup_[Channel1] org.mixxx.effects.filter
QuickEffectForGroup_[Channel2] org.mixxx.effects.filter
QuickEffectForGroup_[Channel3] org.mixxx.effects.filter
QuickEffectForGroup_[Channel4] org.mixxx.effects.filter
SingleEQEffect yes
xFaderCurve 1.00788
xFaderMode 0
xFaderReverse 0

[Modplug]
MaxMixChannels 128
MegabassCutoff 50
MegabassEnabled 0
MegabassLevel 50
NoiseReductionEnabled 0
OversamplingEnabled 1
PerTrackMemoryLimitMB 256
ResamplingMode 1
ReverbDelay 50
ReverbEnabled 0
ReverbLevel 50
StereoSeparation 1
SurroundDelay 50
SurroundEnabled 0
SurroundLevel 50

[OutputEffectRack_[Master]]
focused_effect 0
group_[MasterOutput]_enable 1
mix 1
show_parameters 0

[Playlist]
Directory /home/$LOGINUSR/Musik/Mixx

[Preferences]
geometry 3706,-37,1189,1163

[PreviewDeck1]
keylock 0
quantize 0

[PreviewDeck]
show_previewdeck 0

[QuickEffectRack1_[Channel1]]
focused_effect 0
group_[Channel1]_enable 1
mix 1
show_parameters 0

[QuickEffectRack1_[Channel2]]
focused_effect 0
group_[Channel2]_enable 1
mix 1
show_parameters 0

[QuickEffectRack1_[Channel3]]
focused_effect 0
group_[Channel3]_enable 1
mix 1
show_parameters 0

[QuickEffectRack1_[Channel4]]
focused_effect 0
group_[Channel4]_enable 1
mix 1
show_parameters 0

[Recording]
Album 
Author 
CueEnabled 1
Directory /home/$LOGINUSR/Musik/Mixxx/Recordings
Encoding WAV
FileSize 4 GB
Title 
WAV_BITS 0

[ReplayGain]
InitialDefaultBoost -6
InitialReplayGainBoost 0
ReplayGainEnabled 1

[Sampler10]
keylock 0
quantize 0

[Sampler11]
keylock 0
quantize 0

[Sampler12]
keylock 0
quantize 0

[Sampler13]
keylock 0
quantize 0

[Sampler14]
keylock 0
quantize 0

[Sampler15]
keylock 0
quantize 0

[Sampler16]
keylock 0
quantize 0

[Sampler1]
keylock 0
quantize 0

[Sampler2]
keylock 0
quantize 0

[Sampler3]
keylock 0
quantize 0

[Sampler4]
keylock 0
quantize 0

[Sampler5]
keylock 0
quantize 0

[Sampler6]
keylock 0
quantize 0

[Sampler7]
keylock 0
quantize 0

[Sampler8]
keylock 0
quantize 0

[Sampler9]
keylock 0
quantize 0

[Sampler]
LoadSamplerBank 0
SaveSamplerBank 0

[Samplers]
show_samplers 0

[Shoutcast]
enabled 0

[Skin]
select_big_spinny_coverart 0
show_4decks 1
show_4effectunits 0
show_8_hotcues 1
show_beatgrid_controls 1
show_big_spinny_coverart 0
show_coverart 1
show_eq_kill_buttons 1
show_eq_knobs 1
show_hotcues 1
show_intro_outro_cues 1
show_key_controls 1
show_key_controls_compact 1
show_loopjump_controls_compact 1
show_main_head_mixer 1
show_rate_control_buttons 1
show_rate_controls 1
show_rate_controls_compact 1
show_sampler_fx 0
show_spinnies 1
show_superknobs 0
show_sync_button_compact 1
show_vumeters_compact 1
show_waveforms 1
show_xfader 1
timing_shift_buttons 0

[Soundcard]
Samplerate 48000

[Vamp]
AnalyserBeatPluginID qm-tempotracker:0
AnalyserKeyPluginID qm-keydetector:2

[VinylControl]
cueing_ch1 0
cueing_ch2 0
cueing_ch3 0
cueing_ch4 0
gain 1
mode_ch1 1
mode_ch2 1
mode_ch3 1
mode_ch4 1
show_signal_quality 0
show_vinylcontrol 0

[Visible Built-in Effects]
org.mixxx.effects.autopan 1
org.mixxx.effects.balance 1
org.mixxx.effects.bessel4lvmixeq 1
org.mixxx.effects.bessel8lvmixeq 1
org.mixxx.effects.biquadfullkilleq 1
org.mixxx.effects.bitcrusher 1
org.mixxx.effects.echo 1
org.mixxx.effects.filter 1
org.mixxx.effects.flanger 1
org.mixxx.effects.graphiceq 1
org.mixxx.effects.linkwitzrileyeq 1
org.mixxx.effects.loudnesscontour 1
org.mixxx.effects.metronome 1
org.mixxx.effects.moogladder4filter 1
org.mixxx.effects.parametriceq 1
org.mixxx.effects.phaser 1
org.mixxx.effects.reverb 1
org.mixxx.effects.threebandbiquadeq 1
org.mixxx.effects.tremolo 1

[Waveform]
DefaultZoom 3
EndOfTrackWarningTime 30
OverviewNormalized 0
PlayMarkerPosition 0.5
VisualGain_0 1
VisualGain_1 1
VisualGain_2 1
VisualGain_3 1
WaveformOverviewType 2
WaveformType 12
ZoomSynchronization 1
EOT
                clear
                whiptail --title "Ställ in Mixxx" --msgbox "Allt som behövs för Mixxx är nu inställt." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function connectAutostartStudio {

        if (whiptail --title "Koppla Autostart" --yesno "Detta kommer att koppla allt som behövs till autostart vid inloggning. OK?" 8 78); then
            clear
            installloop=1
            while [ "$installloop" == "1" ]; do
                if [ -d "/home/$LOGINUSR/.config/autostart" ]; then
                    cd /home/$LOGINUSR/.config/autostart
                else
                    mkdir /home/$LOGINUSR/.config/autostart
                    cd /home/$LOGINUSR/.config/autostart
                fi
                if (whiptail --title "Installerat Mixxx ?" --yesno "Har du installerat Mixxx Programmet ?" 8 78); then
                    tee /home/$LOGINUSR/.config/autostart/MixxxPlay.desktop >/dev/null <<EOT
[Desktop Entry]
Type=Application
Exec=/home/$LOGINUSR/Systemet/mixxxplay.sh
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
Name[sv_SE]=MixxxPlay
Comment[sv_SE]=Ser till så låttitlar även fungerar i Mixxx programmet.
X-GNOME-Autostart-Delay=20
EOT
                fi
                tee /home/$LOGINUSR/.config/autostart/Ljudkort.desktop >/dev/null <<EOT
[Desktop Entry]
Type=Application
Exec=/home/$LOGINUSR/Systemet/ljudkort.sh
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
Name[sv_SE]=Ljudkort
Comment[sv_SE]=Ställer in ljudkort för Jack Audio
X-GNOME-Autostart-Delay=12
EOT
                tee /home/$LOGINUSR/.config/autostart/org.rncbc.qjackctl.desktop >/dev/null <<EOT
[Desktop Entry]
Name=QjackCtl
Version=1.0
GenericName=JACK Control
GenericName[de]=JACK-Steuerung
GenericName[fr]=Contrôle JACK
GenericName[it]=Interfaccia di controllo per JACK
GenericName[ru]=Управление JACK
GenericName[uk]=Керування JACK
Comment=QjackCtl is a JACK Audio Connection Kit Qt GUI Interface
Comment[de]=Grafisches Werkzeug zur Steuerung des JACK-Audio-Systems
Comment[fr]=QjackCtl est une interface graphique Qt pour le kit de connexion audio JACK
Comment[it]=QjackCtl è un'interfaccia di controllo per JACK basata su Qt
Comment[ru]=Программа для управления звуковым сервером JACK
Comment[sk]=QjackCtl je grafické rozhranie (Qt) na ovládanie zvukového servera JACK
Comment[uk]=QjackCtl є програмою для керування звуковим сервером JACK
Exec=qjackctl
Icon=org.rncbc.qjackctl
Categories=Audio;AudioVideo;Midi;X-Alsa;X-Jack;Qt;
Keywords=Audio;MIDI;ALSA;JACK;LV2;Qt;
Keywords[uk]=Audio;MIDI;ALSA;JACK;LV2;Qt;Звук;міді;алса;джек;
Terminal=false
Type=Application
StartupWMClass=qjackctl
X-Window-Icon=qjackctl
X-SuSE-translate=true
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
Name[sv_SE]=QjackCtl
Comment[sv_SE]=QjackCtl is a JACK Audio Connection Kit Qt GUI Interface
X-GNOME-Autostart-Delay=10
EOT
                tee /home/$LOGINUSR/.config/autostart/Pulsljudet.desktop >/dev/null <<EOT
[Desktop Entry]
Type=Application
Exec=/home/$LOGINUSR/Systemet/pulseaudio.sh
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
Name[sv_SE]=Pulsljudet
Comment[sv_SE]=Aktiverar pulsaudio
X-GNOME-Autostart-Delay=15
EOT
                tee /home/$LOGINUSR/.config/autostart/rivendell-rdlogin.desktop >/dev/null <<EOT
[Desktop Entry]
Encoding=UTF-8
Terminal=false
Categories=Qt;KDE;Rivendell;
Name=RDLogin
GenericName=Rivendell Login
Exec=rdlogin
Icon=rivendell
Type=Application
Terminal=false
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
Name[sv_SE]=RDLogin
Comment[sv_SE]=Beskrivning saknas
X-GNOME-Autostart-Delay=12
EOT

                clear
                whiptail --title "Koppla Autostart" --msgbox "Vi har nu kopplat allt som behövs för autostart vid inloggning." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function installAudacity {

        if (whiptail --title "Installera Audacity" --yesno "Detta kommer installera Audacity. OK?" 8 78); then
            clear
            whiptail --title "Installera Audacity" --msgbox "Audacity använder vi för inspelning i datorn. Du kommer sen koppla våra specifika inställningar till det." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                sudo apt update &
                sudo apt install audacity -y
                clear
                whiptail --title "Installera Audacity" --msgbox "Audacity har nu installerats. Innan du kopplar våra specifika inställningar.\n\n Starta audacity en gång, och stäng ner det så vi får in inställnings filen i datorn." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function installMixxx {

        if (whiptail --title "Installera Mixxx" --yesno "Detta kommer installera Mixxx. OK?" 8 78); then
            clear
            whiptail --title "Installera Mixxx" --msgbox "Mixxx använder vi för uppspelning när man vill ha vanliga ljudfiler och dra och släppa dem in i datorn." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                sudo apt update &
                sudo apt install mixxx uni2ascii xdotool -y
                clear
                whiptail --title "Installera Mixxx" --msgbox "Mixxx har nu installerats. Innan du kopplar våra specifika inställningar.\n\n Starta mixxx en gång, och stäng ner det så vi får in inställnings filen i datorn." 15 78
                installloop=0
            done
        else
            clear
        fi

    }

    function forStudioComputer {
        while true; do
            CHOICES=$(
                whiptail --title "Välj vad du vill göra" --menu "Välj här vad du vill göra på studio datorn." 20 100 11 \
                    "1)" "Installera Pulseaudio" \
                    "2)" "Installera Audacity" \
                    "3)" "Installera Mixxx" \
                    "4)" "Koppla nu spelas mapp" \
                    "5)" "Installera skript för Nu Spelas" \
                    "6)" "Ställ in QJackCtl" \
                    "7)" "Ställ in Audacity" \
                    "8)" "Ställ in Mixxx" \
                    "9)" "Koppla Autostart" \
                    "10)" "Hjälp & Information" \
                    "11)" "Gå tillbaka" 3>&2 2>&1 1>&3
            )
            result=$(whoami)
            case $CHOICES in
            "1)")
                installPulseaudio
                ;;
            "2)")
                installAudacity
                ;;
            "3)")
                installMixxx
                ;;
            "4)")
                connectReferensStudio
                ;;
            "5)")
                installNowPlayingStudio
                ;;
            "6)")
                setupQJackCtlStudio
                ;;
            "7)")
                setupAudacity
                ;;
            "8)")
                setupMixxx
                ;;
            "9)")
                connectAutostartStudio
                ;;
            "10)")
                StudioHelp
                ;;
            "11)")
                break
                ;;
            esac
            #whiptail --msgbox "$result" 20 78
        done
    }

    function installGlassCoder {
        if (whiptail --title "Installera GlassCoder" --yesno "Detta kommer att installera GlassCoder. OK?" 8 78); then
            clear
            whiptail --title "Installera GlassCoder" --msgbox "GlassCoder används för att skicka ljud till ShoutCast." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                sudo apt update
                sudo apt install curl git docbook-xsl fop xsltproc autoconf automake libtool g++ qtbase5-dev libqt5sql5-mysql libmagick++-dev qttools5-dev-tools libexpat1 libexpat1-dev libssl-dev libsamplerate-dev libsndfile-dev libcdparanoia-dev libcoverart-dev libdiscid-dev libmusicbrainz5-dev libid3-dev libtag1-dev libcurl4-gnutls-dev libpam0g-dev libsoundtouch-dev docbook5-xml libxml2-utils docbook-xsl-ns xsltproc fop make libsystemd-dev libjack-jackd2-dev libasound2-dev libflac-dev libflac++-dev libmp3lame-dev libmad0-dev libtwolame-dev python3 python3-pycurl python3-pymysql python3-serial python3-requests python3-mysqldb libqt5webkit5-dev -y
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                VG="$(curl --silent "https://api.github.com/repos/ElvishArtisan/GlassCoder/releases/latest" | jq -r .tag_name)"
                FG="$(curl --silent "https://api.github.com/repos/ElvishArtisan/GlassCoder/releases/latest" | jq -r .tarball_url)"
                tee -a /home/$LOGINUSR/Systemet/glassversion >/dev/null <<EOT
giver="$VG"
EOT
                mkdir /home/$LOGINUSR/Systemet/GlassCoder
                cd /home/$LOGINUSR/Systemet/GlassCoder
                curl -sL --continue-at - "$FG" -o "/home/$LOGINUSR/Systemet/GlassCoder/GlassCoder.tar.xz"
                tar -xf GlassCoder.tar.xz --strip-components=1
                rm GlassCoder.tar.xz
                ./autogen.sh
                ./configure --disable-docbook
                make
                sudo make install
                clear
                whiptail --title "Installera GlassCoder" --msgbox "Installationen av GlassCoder har blivit slutförd." 15 78
                installloop=0
            done

        else
            clear
        fi

    }

    function installStereoTool {
        if (whiptail --title "Installera Stereo Tool" --yesno "Detta kommer att installera Stereo Tool. OK?" 8 78); then
            clear
            whiptail --title "Installera Stereo Tool" --msgbox "Stereo Tool används för att behandla ljudet samt skicka ljud till Sändaren. Vissa manuella åtgärder lär du göra själv." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                FST="https://www.stereotool.com/download/stereo_tool_gui_jack_64"

                curl -sL --continue-at - "$FST" -o "/home/$LOGINUSR/Systemet/stereotool"
                chmod u+x /home/$LOGINUSR/Systemet/stereotool
                tee /home/$LOGINUSR/Skrivbord/Ljudprocessor.desktop >/dev/null <<EOT
[Desktop Entry]
Name=Ljudprocessor
Exec=/home/$LOGINUSR/Systemet/stereotool
Comment=Programmet för att behandla ljud
Terminal=false
Icon=yast_soundcard
Type=Application
EOT
                clear
                whiptail --title "Installera Stereo Tool" --msgbox "Vi har nu installerat Stereo Tool. Kom ihåg att du lär aktivera licens osv i programmet." 15 78
                installloop=0
            done

        else
            clear
        fi

    }

    function installButt {
        if (whiptail --title "Installera Butt" --yesno "Detta kommer att installera Butt. OK?" 8 78); then
            clear
            whiptail --title "Installera Butt" --msgbox "Butt (Broadcast Using This Tool) används för referens inspelningar." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                sudo apt update
                sudo apt install curl libfltk1.3-dev portaudio19-dev libopus-dev libmp3lame-dev libvorbis-dev libogg-dev libflac-dev libdbus-1-dev libsamplerate0-dev libssl-dev libcurl4-openssl-dev libportmidi-dev -y
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                FB="https://danielnoethen.de/butt/release/1.45.0/butt-1.45.0.tar.gz"

                mkdir /home/$LOGINUSR/Systemet/Butt
                cd /home/$LOGINUSR/Systemet/Butt
                curl -sL --continue-at - "$FB" -o "/home/$LOGINUSR/Systemet/Butt/Butt.tar.xz"
                tar -xf Butt.tar.xz --strip-components=1
                rm Butt.tar.xz
                ./configure --disable-aac
                make
                sudo make install
                clear
                whiptail --title "Installera Butt" --msgbox "Installationen av Butt har blivit slutförd." 15 78
                installloop=0
            done

        else
            clear
        fi

    }

    function installClock {
        if (whiptail --title "Installera OnAirScreen" --yesno "Detta kommer installera OnAirScreen mjukvaran. OK?" 8 78); then
            clear
            whiptail --title "Installera OnAirScreen" --msgbox "OnAirScreen används i studio och kontrollrum för att se tid och om man är onair." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                sudo apt update
                sudo apt install curl qtbase5-dev qt5-qmake pyqt5-dev-tools python3-pip python3-pyqt5 python3-ntplib python3-distutils python3-dev python3-pip python3-setuptools -y
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                mkdir /home/$LOGINUSR/Systemet/OnAirScreen
                cd /home/$LOGINUSR/Systemet/OnAirScreen
                cp $RUNFOLDER/OnAirScreen.tar.gz /home/$LOGINUSR/Systemet/OnAirScreen/OnAirScreen.tar.xz
                cp $RUNFOLDER/rslogotyp.png /home/$LOGINUSR/Systemet/rslogotyp.png
                tar -xf OnAirScreen.tar.xz --strip-components=1
                rm OnAirScreen.tar.xz
                make
                if [ -d "/home/$LOGINUSR/.config/astrastudio" ]; then
                    cd /home/$LOGINUSR/.config/astrastudio
                else
                    mkdir /home/$LOGINUSR/.config/astrastudio
                    cd /home/$LOGINUSR/.config/astrastudio
                fi
                mkdir /home/$LOGINUSR/.config/astrastudio
                tee /home/$LOGINUSR/.config/astrastudio/OnAirScreen.conf >/dev/null <<EOT
[Clock]
digital=true
digitaldigitcolor=#3232ff
digitalhourcolor=#3232ff
digitalsecondcolor=#ff9900
logoUpper=false
logopath=/home/$LOGINUSR/Systemet/rslogotyp.png
showSeconds=true
showSecondsInOneLine=false
staticColon=false
useTextClock=true

[Fonts]
AIR1FontName=FreeSans
AIR1FontSize=24
AIR1FontWeight=75
AIR2FontName=FreeSans
AIR2FontSize=24
AIR2FontWeight=75
AIR3FontName=FreeSans
AIR3FontSize=24
AIR3FontWeight=75
AIR4FontName=FreeSans
AIR4FontSize=24
AIR4FontWeight=75
LED1FontName=FreeSans
LED1FontSize=24
LED1FontWeight=75
LED2FontName=FreeSans
LED2FontSize=24
LED2FontWeight=75
LED3FontName=FreeSans
LED3FontSize=24
LED3FontWeight=75
LED4FontName=FreeSans
LED4FontSize=24
LED4FontWeight=75
SloganFontName=FreeSans
SloganFontSize=18
SloganFontWeight=75
StationNameFontName=FreeSans
StationNameFontSize=24
StationNameFontWeight=75

[Formatting]
dateFormat=dddd dd MMMM yyyy
isAmPm=false
textClockLanguage=Swedish

[%General]
fullscreen=false
replacenow=true
replacenowtext=
slogan=Din lokala radio
slogancolor=#ffaa00
stationcolor=#ffaa00
stationname=Radio Sandviken
updatecheck=false
updateincludebeta=false
updatekey=

[LED1]
activebgcolor=#ff0000
activetextcolor=#ffffff
autoflash=false
text=ON AIR
timedflash=false
used=true

[LED2]
activebgcolor=#dcdc00
activetextcolor=#ffffff
autoflash=false
text=PHONE
timedflash=false
used=false

[LED3]
activebgcolor=#00c8c8
activetextcolor=#ffffff
autoflash=false
text=DOORBELL
timedflash=false
used=false

[LED4]
activebgcolor=#ff00ff
activetextcolor=#ffffff
autoflash=false
text=EAS ACTIVE
timedflash=false
used=false

[LEDS]
inactivebgcolor=#222222
inactivetextcolor=#555555

[NTP]
ntpcheck=false
ntpcheckserver=pool.ntp.org

[Network]
httpport=8010
multicast_address=239.194.0.1
udpport=3310

[Timers]
AIR1activebgcolor=#ff0000
AIR1activetextcolor=#ffffff
AIR2activebgcolor=#ff0000
AIR2activetextcolor=#ffffff
AIR3activebgcolor=#ff0000
AIR3activetextcolor=#ffffff
AIR4activebgcolor=#ff0000
AIR4activetextcolor=#ffffff
TimerAIR1Enabled=false
TimerAIR1Text=Mic
TimerAIR2Enabled=false
TimerAIR2Text=Phone
TimerAIR3Enabled=false
TimerAIR3Text=Timer
TimerAIR4Enabled=true
TimerAIR4Text=S\xe4ndning
TimerAIRMinWidth=200
air1iconpath=:/mic_icon.png/images/mic_icon.png
air2iconpath=:/phone_icon/images/phone_icon.png
air3iconpath=:/timer_icon/images/timer_icon.png
air4iconpath=:/stream_icon/images/antenna2.png

[WeatherWidget]
owmAPIKey=b0df1c769196f91036f8638a775e7806
owmCityID=2680075
owmLanguage=Swedish
owmUnit=Celsius
owmWidgetEnabled=true
EOT
                clear
                whiptail --title "Installera OnAirScreen" --msgbox "Installationen av OnAirScreen har blivit slutförd." 15 78
                installloop=0
            done

        else
            clear
        fi

    }

    function forLjudprocessor {
        while true; do
            CHOICES=$(
                whiptail --title "Välj vad du vill göra" --menu "Här installerar du unika program och inställningar för ljudprocessorn." 16 100 9 \
                    "1)" "Installera GlassCoder" \
                    "2)" "Installera Butt" \
                    "3)" "Installera Stereo Tool" \
                    "4)" "Hjälp & Information" \
                    "9)" "Gå tillbaka" 3>&2 2>&1 1>&3
            )
            result=$(whoami)
            case $CHOICES in
            "1)")
                installGlassCoder
                ;;
            "2)")
                installButt
                ;;
            "3)")
                installStereoTool
                ;;
            "4)")
                ProcessHelp
                ;;
            "9)")
                break
                ;;
            esac
            #whiptail --msgbox "$result" 20 78
        done
    }

    function quietBoot {
        if (whiptail --title "Aktivera Quiet Boot" --yesno "Detta kommer aktivera Quiet Boot. OK?" 8 78); then
            clear
            whiptail --title "Aktivera Quiet Boot" --msgbox "Quiet Boot döljer den tråkiga uppstarten av datorn, med en snygg splash screen istället." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT\=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' /etc/default/grub
                sudo update-grub
                clear
                whiptail --title "Aktivera Quiet Boot" --msgbox "Nu är det aktiverat, du behöver start om din dator." 15 78
                installloop=0
            done

        else
            clear
        fi

    }

    function autoLogin {
        if (whiptail --title "Aktivera Auto Login" --yesno "Detta kommer aktivera auto login. OK?" 8 78); then
            clear
            installloop=1
            while [ "$installloop" == "1" ]; do
                sudo groupadd -r autologin
                sudo usermod -a -G autologin $LOGINUSR
                sudo_setini '/etc/lightdm/lightdm.conf' 'Seat:*' 'autologin-user' $LOGINUSR
                clear
                whiptail --title "Aktivera Auto Login" --msgbox "Nu är auto login aktiverat. Nästa gång du startar datorn kommer den logga in automatiskt." 15 78
                installloop=0
            done

        else
            clear
        fi

    }

    function OtherHelp {
        whiptail --textbox --scrolltext $RUNFOLDER/otherhelp.txt 20 80
    }

    function otherStuff {
        while true; do
            CHOICES=$(
                whiptail --title "Välj vad du vill göra" --menu "Vad vill du göra, det finns mer under respektive dator med unika inställningar." 20 100 10 \
                    "1)" "Anslut musik server till Rivendell" \
                    "2)" "För Master Datorn" \
                    "3)" "För Studio Datorn" \
                    "4)" "För Ljudprocessor Datorn" \
                    "5)" "För Klock Datorn" \
                    "6)" "Koppla användaren till sudo gruppen." \
                    "7)" "Aktivera Quiet Boot" \
                    "8)" "Aktivera Auto Login" \
                    "9)" "Hjälp & Information" \
                    "10)" "Gå tillbaka" 3>&2 2>&1 1>&3
            )
            result=$(whoami)
            case $CHOICES in
            "1)")
                connectAudioServer
                ;;
            "2)")
                forMasterComputer
                ;;
            "3)")
                forStudioComputer
                ;;
            "4)")
                forLjudprocessor
                ;;
            "5)")
                forClockComputer
                ;;
            "6)")
                addtoSudo
                ;;
            "7)")
                quietBoot
                ;;
            "8)")
                autoLogin
                ;;
            "9)")
                OtherHelp
                ;;
            "10)")
                break
                ;;
            esac
            #whiptail --msgbox "$result" 20 78
        done
    }

    function installVNC {
        if (whiptail --title "Installera VNC" --yesno "Detta kommer installera VNC på denna dator. OK?" 8 78); then
            clear
            whiptail --title "Installera VNC" --msgbox "VNC behövs för fjärråtkomst till datorn. Och det kommer inte att ha access från internet. Endast på ditt lokala nätverk." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                sudo apt install curl x11vnc -y
                sudo x11vnc -storepasswd /etc/x11vnc.pwd
                sudo tee -a /etc/systemd/system/x11vnc.service >/dev/null <<EOT
[Unit]
Description=Start x11vnc at startup.
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth /etc/x11vnc.pwd -rfbport 5900 -shared -o /var/log/x11vnc.log

[Install]
WantedBy=multi-user.target
EOT
                sudo systemctl enable x11vnc
                sudo systemctl start x11vnc
                clear
                whiptail --title "Installera VNC" --msgbox "Installationen av VNC är nu slutförd." 15 78
                installloop=0
            done

        else
            clear
        fi

    }

    function updateRivendell {
        if (whiptail --title "Uppdatera Rivendell" --yesno "Detta kommer att uppdatera Rivendell om ny version finns. OK?" 8 78); then
            clear
            whiptail --title "Uppdatera Rivendell" --msgbox "Den gamla versionen av Rivendell kommer att avinstalleras och den nya kommer att installeras. Det kan ta lite tid." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                V="$(curl --silent "https://api.github.com/repos/ElvishArtisan/rivendell/releases/latest" | jq -r .tag_name)"
                F="$(curl --silent "https://api.github.com/repos/ElvishArtisan/rivendell/releases/latest" | jq -r .tarball_url)"
                cd /home/$LOGINUSR/Systemet/rivendell
                source /home/$LOGINUSR/Systemet/version
                #giver
                if [ "$giver" == "$V" ]; then
                    whiptail --title "Uppdatera Rivendell" --msgbox "Ny version existerar, låt oss uppdatera." 15 78
                    clear
                    sudo systemctl stop rivendell
                    sudo make uninstall
                    if [ -d "/home/$LOGINUSR/Systemet" ]; then
                        cd /home/$LOGINUSR/Systemet
                    else
                        mkdir /home/$LOGINUSR/Systemet
                        cd /home/$LOGINUSR/Systemet
                    fi
                    mv /home/$LOGINUSR/Systemet/rivendell /home/$LOGINUSR/Systemet/rivendell-old
                    sudo apt update &
                    sudo apt upgrade -y
                    mkdir rivendell
                    cd rivendell
                    curl -sL --continue-at - "$F" -o "/home/$LOGINUSR/Systemet/rivendell/rivendell.tar.xz"
                    tar -xf rivendell.tar.xz --strip-components=1
                    rm rivendell.tar.xz
                    ./autogen.sh
                    export PATH=/sbin:$PATH
                    export DOCBOOK_STYLESHEETS=/usr/share/xml/docbook/stylesheet/docbook-xsl-ns
                    echo DOCBOOK_STYLESHEETS=/usr/share/xml/docbook/stylesheet/docbook-xsl-ns >>~/.bashrc
                    ./configure --prefix=/usr --libdir=/usr/lib --libexecdir=/var/www/rd-bin --sysconfdir=/etc/apache2/conf-enabled --enable-rdxport-debug MUSICBRAINZ_LIBS="-ldiscid -lmusicbrainz5cc -lcoverartcc"
                    make
                    sudo ln -sf ../mods-available/cgid.conf /etc/apache2/mods-enabled/cgid.conf
                    sudo ln -sf ../mods-available/cgid.load /etc/apache2/mods-enabled/cgid.load
                    sudo systemctl restart apache2
                    sudo make install
                    sudo cp ./apis/pypad/api/pypad.py /usr/lib/python3/dist-packages/
                    sudo systemctl start rivendell
                    sudo systemctl enable rivendell
                    sudo rddbmgr --modify
                    clear
                    whiptail --title "Uppdatera Rivendell" --msgbox "Uppdateringen är nu slutförd. Vi rekommenderar att du startar om datorn." 15 78
                    installloop=0
                else
                    clear
                    whiptail --title "Uppdatera Rivendell" --msgbox "Det finns ingen ny version tillgänglig." 15 78
                    installloop=0
                fi
            done
        else
            clear
        fi
    }

    function installPulseaudio {
        if (whiptail --title "Pulseaudio Installation" --yesno "Detta kommer att installera pulseaudio. OK?" 8 78); then
            clear
            whiptail --title "Pulseaudio Installation" --msgbox "Pulsaudio behövs för att få ljudet från andra applikationer till Jack Audio.\n\nVi kommer skapa en fil i Systemet mappen med ett skript för pulseaudio." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                sudo apt-get install curl pulseaudio-module-jack -y
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                tee -a /home/$LOGINUSR/Systemet/pulseaudio.sh >/dev/null <<EOT
systemctl --user start pulseaudio.service; pactl load-module module-jack-sink channels=2; pactl load-module module-jack-source; pacmd set-default-sink jack_out
EOT
                chmod u+x /home/$LOGINUSR/Systemet/pulseaudio.sh
                clear
                whiptail --title "Pulseaudio Installation" --msgbox "Pulsaudio är nu installerat i Systemet mappen. Detta behövs startas vid inloggning." 15 78
                installloop=0
            done
        else
            clear
        fi
    }

    function createSoundcard {
        if (whiptail --title "Skapa Ljudkort Skript?" --yesno "Detta kommer skapa ett ljudkorts skript i Systemet mappen. OK?" 8 78); then
            clear
            whiptail --title "Ljudkort Skript" --msgbox "Detta ljudkort skript vi kommer skapa behöver starta efter QJackCtl när man loggar in.\nDu kommer få ange namnen till ljudkorten du har." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                clear
                SELECTED=$(whiptail --title "Hur många ljudkort?" --radiolist \
                    "Hur många ljudkort behöver du ?" 20 100 10 \
                    "1" "Ett ljudkort" ON \
                    "2" "Två ljudkort" OFF \
                    "3" "Tre ljudkort" OFF \
                    "4" "Fyra ljudkort" OFF \
                    "5" "Fem ljudkort" OFF \
                    "6" "Sex ljudkort" OFF 3>&1 1>&2 2>&3)

                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                clear
                whiptail --title "Ljudkort Skript" --msgbox "Du kommer nu få skriva in ljudkortens namn. Du ser dom när du skriver: cat /proc/asound/cards i terminalen. Du får en lista på ljudkorten.\nDu behöver namnet som står inom []. Som exempel 0 [CODEC så namnet är CODEC" 15 78
                if [ $SELECTED -eq 1 ]; then
                    clear
                    SND1NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på ljudkortet" 8 40 3>&1 1>&2 2>&3)
                    tee -a /home/$LOGINUSR/Systemet/ljudkort.sh >/dev/null <<EOT
#!/bin/dash

/usr/bin/alsa_in -j "$SND1NAME In" -d hw:$SND1NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND1NAME Ut" -d hw:$SND1NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

echo "Ljudkort Skapat"
EOT
                    chmod u+x /home/$LOGINUSR/Systemet/ljudkort.sh

                else
                    if [ $SELECTED -eq 2 ]; then
                        clear
                        SND1NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på första ljudkortet" 8 40 3>&1 1>&2 2>&3)
                        SND2NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på andra ljudkortet" 8 40 3>&1 1>&2 2>&3)
                        tee -a /home/$LOGINUSR/Systemet/ljudkort.sh >/dev/null <<EOT
#!/bin/dash

/usr/bin/alsa_in -j "$SND1NAME In" -d hw:$SND1NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND1NAME Ut" -d hw:$SND1NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND2NAME In" -d hw:$SND2NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND2NAME Ut" -d hw:$SND2NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

echo "Ljudkort Skapat"
EOT
                        chmod u+x /home/$LOGINUSR/Systemet/ljudkort.sh

                    else
                        if [ $SELECTED -eq 3 ]; then
                            clear
                            SND1NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på första ljudkortet" 8 40 3>&1 1>&2 2>&3)
                            SND2NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på andra ljudkortet" 8 40 3>&1 1>&2 2>&3)
                            SND3NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på tredje ljudkortet" 8 40 3>&1 1>&2 2>&3)
                            tee -a /home/$LOGINUSR/Systemet/ljudkort.sh >/dev/null <<EOT
#!/bin/dash

/usr/bin/alsa_in -j "$SND1NAME In" -d hw:$SND1NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND1NAME Ut" -d hw:$SND1NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND2NAME In" -d hw:$SND2NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND2NAME Ut" -d hw:$SND2NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND3NAME In" -d hw:$SND3NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND3NAME Ut" -d hw:$SND3NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

echo "Ljudkort Skapat"
EOT
                            chmod u+x /home/$LOGINUSR/Systemet/ljudkort.sh

                        else
                            if [ $SELECTED -eq 4 ]; then
                                clear
                                SND1NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på första ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                SND2NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på andra ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                SND3NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på tredje ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                SND4NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på fjärde ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                tee -a /home/$LOGINUSR/Systemet/ljudkort.sh >/dev/null <<EOT
#!/bin/dash

/usr/bin/alsa_in -j "$SND1NAME In" -d hw:$SND1NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND1NAME Ut" -d hw:$SND1NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND2NAME In" -d hw:$SND2NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND2NAME Ut" -d hw:$SND2NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND3NAME In" -d hw:$SND3NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND3NAME Ut" -d hw:$SND3NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND4NAME In" -d hw:$SND4NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND4NAME Ut" -d hw:$SND4NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

echo "Ljudkort Skapat"
EOT
                                chmod u+x /home/$LOGINUSR/Systemet/ljudkort.sh

                            else
                                if [ $SELECTED -eq 5 ]; then
                                    clear
                                    SND1NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på första ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                    SND2NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på andra ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                    SND3NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på tredje ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                    SND4NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på fjärde ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                    SND5NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på femte ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                    tee -a /home/$LOGINUSR/Systemet/ljudkort.sh >/dev/null <<EOT
#!/bin/dash

/usr/bin/alsa_in -j "$SND1NAME In" -d hw:$SND1NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND1NAME Ut" -d hw:$SND1NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND2NAME In" -d hw:$SND2NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND2NAME Ut" -d hw:$SND2NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND3NAME In" -d hw:$SND3NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND3NAME Ut" -d hw:$SND3NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND4NAME In" -d hw:$SND4NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND4NAME Ut" -d hw:$SND4NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND5NAME In" -d hw:$SND5NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND5NAME Ut" -d hw:$SND5NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

echo "Ljudkort Skapat"
EOT
                                    chmod u+x /home/$LOGINUSR/Systemet/ljudkort.sh

                                else
                                    if [ $SELECTED -eq 6 ]; then
                                        clear
                                        SND1NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på första ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                        SND2NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på andra ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                        SND3NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på tredje ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                        SND4NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på fjärde ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                        SND5NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på femte ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                        SND6NAME=$(whiptail --title "Ljudkorts namn" --inputbox "Ange namnet på sjätte ljudkortet" 8 40 3>&1 1>&2 2>&3)
                                        tee -a /home/$LOGINUSR/Systemet/ljudkort.sh >/dev/null <<EOT
#!/bin/dash

/usr/bin/alsa_in -j "$SND1NAME In" -d hw:$SND1NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND1NAME Ut" -d hw:$SND1NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND2NAME In" -d hw:$SND2NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND2NAME Ut" -d hw:$SND2NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND3NAME In" -d hw:$SND3NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND3NAME Ut" -d hw:$SND3NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND4NAME In" -d hw:$SND4NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND4NAME Ut" -d hw:$SND4NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND5NAME In" -d hw:$SND5NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND5NAME Ut" -d hw:$SND5NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

/usr/bin/alsa_in -j "$SND6NAME In" -d hw:$SND6NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &
/usr/bin/alsa_out -j "$SND6NAME Ut" -d hw:$SND6NAME -r 48000 -p 2048 -q 1 2>&1 1> /dev/null &

echo "Ljudkort Skapat"
EOT
                                        chmod u+x /home/$LOGINUSR/Systemet/ljudkort.sh

                                    else
                                        clear
                                    fi
                                fi
                            fi
                        fi
                    fi
                fi

                clear
                whiptail --title "Ljudkort Skript" --msgbox "Vi har nu skapat ett ljudkort skript i Systemet mappen.\nDetta skript ska starta vid inloggning." 15 78
                installloop=0
            done
        else
            clear
        fi
    }

    function installJackMixer {
        if (whiptail --title "Installera Jack Mixer ?" --yesno "Detta kommer installera senaste version av Jack Mixer. OK?" 8 78); then
            clear
            whiptail --title "Jack Mixer Installation" --msgbox "Jack Mixer används bland annat i Master Datorn och Ljudprocess datorn. Det finns färdiga mixer data sen du kan koppla till rätt dator." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                sudo apt-get install curl cython3 git python3-docutils python3-appdirs python3-platformdirs build-essential jackd2 libglib2.0-dev libjack-jackd2-dev meson pkgconf python3-gi python3-xdg -y
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                git clone https://github.com/jack-mixer/jack_mixer
                cd jack_mixer
                sed -i -e \
                    's|import sys$|import sys, sysconfig\nsys.path.insert(0, sysconfig.get_path("purelib"))|' \
                    jack_mixer/__main__.py
                meson setup builddir --prefix=/usr --buildtype=release
                ninja -C builddir
                sudo ninja -C builddir install
                clear
                whiptail --title "Jack Mixer Installation" --msgbox "Installationen av Jack Mixer är nu klar och kan användas med Jack Audio.\n\nFör att starta en sparad mixer du kan använda följade kommando:\n\njack_mixer -c /home/rs/Systemet/mixer.xml" 15 78
                installloop=0
            done
        else
            clear
        fi
    }

    function installJack {
        if (whiptail --title "Installera Jack Audio ?" --yesno "Detta kommer installera Jack Audio. OK?" 8 78); then
            clear
            whiptail --title "Jack Audio Installation" --msgbox "Jack Audio är ett verktyg som hjälper oss att styra ljudet dit vi vill att det ska gå.\n\nDet kommer att anpassas så det fungerar ihop med Rivendell." 15 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                sudo apt install jackd qjackctl -y
                if (whiptail --title "Köra Rivendell ?" --yesno "Kommer du köra Rivendell på denna maskin?" 8 78); then
                    clear
                    sudo tee -a /etc/profile.d/rivendell-env.sh >/dev/null <<EOT
#
# Run jackd(1) in promiscuous mode
#
export JACK_PROMISCUOUS_SERVER=audio
EOT
                    sudo tee -a /etc/environment >/dev/null <<EOT
JACK_PROMISCUOUS_SERVER=audio
EOT

                    clear
                    whiptail --title "Jack Audio Installation" --msgbox "Installationen av Jack Audio och programvaran QJackCtl är nu slutförd.\n\nFör att aktivera Jack Audio i Rivendell gör du så här:\n\n1. Gå till Jack Settings under Manage Hosts i RDAdmin för denna dator.\n2. Markera boxen Starta Jack Audio och i Jack Command line lägg till:\n/usr/bin/jackd --name default -d dummy -r 48000 -C 2 -p 2048" 15 78
                    installloop=0
                else
                    clear
                    whiptail --title "Jack Audio Installation" --msgbox "Installationen av Jack Audio och programvaran QJackCtl är nu slutförd." 15 78
                    installloop=0
                fi
            done
        else
            clear
        fi

    }

    function installRivWeb {
        if (whiptail --title "Installera Rivendell Web" --yesno "Detta kommer installera Rivendell Web Broadcast. OK?" 8 78); then
            clear
            if (whiptail --title "Master Datorn ?" --yesno "Detta ska installeras på master datorn, är detta master datorn ?" 12 78); then
                installloop=1
                while [ "$installloop" == "1" ]; do
                    sudo apt install apache2 -y
                    sudo a2enmod rewrite
                    sudo tee /etc/apache2/apache2.conf >/dev/null <<EOT
DefaultRuntimeDir \${APACHE_RUN_DIR}
PidFile \${APACHE_PID_FILE}
Timeout 300
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
User \${APACHE_RUN_USER}
Group \${APACHE_RUN_GROUP}
HostnameLookups Off
ErrorLog \${APACHE_LOG_DIR}/error.log
LogLevel warn
IncludeOptional mods-enabled/*.load
IncludeOptional mods-enabled/*.conf
Include ports.conf
<Directory />
	Options FollowSymLinks
	AllowOverride None
	Require all denied
</Directory>

<Directory /usr/share>
	AllowOverride None
	Require all granted
</Directory>

<Directory /var/www/>
	Options Indexes FollowSymLinks
	AllowOverride All
	Require all granted
</Directory>

AccessFileName .htaccess

<FilesMatch "^\.ht">
	Require all denied
</FilesMatch>

LogFormat "%v:%p %h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" vhost_combined
LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %O" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent

IncludeOptional conf-enabled/*.conf

IncludeOptional sites-enabled/*.conf
EOT
                    sudo apt install php ffmpeg php-{common,mysql,xml,xmlrpc,curl,gd,imagick,cli,dev,imap,mbstring,opcache,soap,zip,intl,pdo} -y
                    sudo systemctl restart apache2
                    cd /var/www/html
                    sudo rm index.html
                    F="$(curl --silent "https://api.github.com/repos/olsson82/rivendellweb/releases/latest" | jq -r .tarball_url)"
                    sudo curl -sL --continue-at - "$F" -o "/var/www/html/rivendellweb.tar.xz"
                    sudo tar -xf rivendellweb.tar.xz --strip-components=1
                    sudo rm rivendellweb.tar.xz
                    sudo chmod -R 777 /var/www/html/
                    clear
                    whiptail --title "Installera Rivendell Web" --msgbox "Installationen av Rivendell Web Broadcast är nu klar, och är redo att börja användas." 15 78
                    installloop=0
                done
            else
                clear
            fi
        else
            clear
        fi

    }

    function installRivendell {
        if (whiptail --title "Installera Rivendell ?" --yesno "Detta kommer att installera senaste versionen av Rivendell. OK?" 8 78); then
            clear
            whiptail --title "Rivendell Radio Installation" --msgbox "Denna installation kommer installera allt som krävs för att få Rivendell att fungera.\nUnder installation kommer du behöva logga in som sudo.\nInstallationen kan ta ett tag beroende på din dator.\nUnder installation kommer du att få fylla i information till Rivendells databas." 30 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                if [ -d "/home/$LOGINUSR/Systemet" ]; then
                    cd /home/$LOGINUSR/Systemet
                else
                    mkdir /home/$LOGINUSR/Systemet
                    cd /home/$LOGINUSR/Systemet
                fi
                V="$(curl --silent "https://api.github.com/repos/ElvishArtisan/rivendell/releases/latest" | jq -r .tag_name)"
                F="$(curl --silent "https://api.github.com/repos/ElvishArtisan/rivendell/releases/latest" | jq -r .tarball_url)"
                tee -a /home/$LOGINUSR/Systemet/version >/dev/null <<EOT
giver="$V"
EOT
                mkdir rivendell
                cd rivendell
                curl -sL --continue-at - "$F" -o "/home/$LOGINUSR/Systemet/rivendell/rivendell.tar.xz"
                tar -xf rivendell.tar.xz --strip-components=1
                rm rivendell.tar.xz
                sudo apt install curl apache2 mariadb-server docbook-xsl fop xsltproc autoconf automake libtool g++ qtbase5-dev libqt5sql5-mysql libmagick++-dev qttools5-dev-tools libexpat1 libexpat1-dev libssl-dev libsamplerate-dev libsndfile-dev libcdparanoia-dev libcoverart-dev libdiscid-dev libmusicbrainz5-dev libid3-dev libtag1-dev libcurl4-gnutls-dev libpam0g-dev libsoundtouch-dev docbook5-xml libxml2-utils docbook-xsl-ns xsltproc fop make libsystemd-dev libjack-jackd2-dev libasound2-dev libflac-dev libflac++-dev libmp3lame-dev libmad0-dev libtwolame-dev python3 python3-pycurl python3-pymysql python3-serial python3-requests python3-mysqldb libqt5webkit5-dev -y
                ./autogen.sh
                export PATH=/sbin:$PATH
                export DOCBOOK_STYLESHEETS=/usr/share/xml/docbook/stylesheet/docbook-xsl-ns
                echo DOCBOOK_STYLESHEETS=/usr/share/xml/docbook/stylesheet/docbook-xsl-ns >>~/.bashrc
                ./configure --prefix=/usr --libdir=/usr/lib --libexecdir=/var/www/rd-bin --sysconfdir=/etc/apache2/conf-enabled --enable-rdxport-debug MUSICBRAINZ_LIBS="-ldiscid -lmusicbrainz5cc -lcoverartcc"
                make
                sudo ln -sf ../mods-available/cgid.conf /etc/apache2/mods-enabled/cgid.conf
                sudo ln -sf ../mods-available/cgid.load /etc/apache2/mods-enabled/cgid.load
                sudo systemctl restart apache2
                sudo mysql -e "CREATE USER 'rduser'@'%' IDENTIFIED BY 'hackme';"
                sudo mysql -e "CREATE DATABASE Rivendell;"
                sudo mysql -e "GRANT ALL PRIVILEGES ON Rivendell.* TO rduser@'%' WITH GRANT OPTION;"
                sudo mysql -e "FLUSH PRIVILEGES;"
                sudo adduser --uid 150 --system --group --home=/var/snd rivendell
                sudo chgrp rivendell /var/snd
                sudo chmod g+w /var/snd
                sudo adduser --system --no-create-home pypad
                sudo adduser root rivendell
                sudo usermod -a -G rivendell,audio,dialout $LOGINUSR
                sudo make install
                sudo ldconfig
                sudo cp conf/rd.conf-sample /etc/rd.conf
                clear
                whiptail --title "Koppla till databasen" --msgbox "Vi behöver koppla rivendell till databasen som har all information. Du kommer få fylla i uppgifter dit ni har databasen." 15 78
                clear
                DBIPNO=$(whiptail --title "IP Address" --inputbox "Ange ip numret till databasen" 8 40 3>&1 1>&2 2>&3)
                DBUSER=$(whiptail --title "Username" --inputbox "Ange användarnamnet till databasen" 8 40 3>&1 1>&2 2>&3)
                DBPASS=$(whiptail --title "Password" --passwordbox "Ange lösenord till databasen" 8 40 3>&1 1>&2 2>&3)
                DBDATA=$(whiptail --title "Database" --inputbox "Ange databasens namn" 8 40 3>&1 1>&2 2>&3)
                sudo_setini '/etc/rd.conf' 'Identity' 'RnRmlOwner' $LOGINUSR
                sudo_setini '/etc/rd.conf' 'Identity' 'RnRmlGroup' $LOGINUSR
                sudo_setini '/etc/rd.conf' 'mySQL' 'Hostname' $DBIPNO
                sudo_setini '/etc/rd.conf' 'mySQL' 'Loginname' $DBUSER
                sudo_setini '/etc/rd.conf' 'mySQL' 'Password' $DBPASS
                sudo_setini '/etc/rd.conf' 'mySQL' 'Database' $DBDATA
                sudo cp ./apis/pypad/api/pypad.py /usr/lib/python3/dist-packages/
                sudo rddbmgr --create --generate-audio
                sudo systemctl start rivendell
                sudo systemctl enable rivendell
                clear
                whiptail --title "Rivendell Radio Installation" --msgbox "Installationen av Rivendell Radio är klar. Vi rekommenderar att du startar om din dator för att slutföra några ändringar." 15 78
                installloop=0
            done
        else
            clear
        fi
    }

    function installSonoBus {
        if (whiptail --title "Installera SonoBus ?" --yesno "Detta kommer att installera senaste versionen av SonoBus. OK?" 8 78); then
            clear
            whiptail --title "SonoBus Installation" --msgbox "SonoBus är ett kostnadsfritt program för att sända ljud med low latency över internet från bland annat en telefon, dator m.m." 30 78
            installloop=1
            while [ "$installloop" == "1" ]; do
                echo "deb http://pkg.sonobus.net/apt stable main" | sudo tee /etc/apt/sources.list.d/sonobus.list
                sudo wget -O /etc/apt/trusted.gpg.d/sonobus.gpg https://pkg.sonobus.net/apt/keyring.gpg
                sudo apt update && sudo apt install sonobus -y
                tee /home/$LOGINUSR/Skrivbord/sonobus.desktop >/dev/null <<EOT
[Desktop Entry]
Name=SonoBus
Comment=High Quality Network Audio Streaming
GenericName=Network Audio Streaming Software
Exec=sonobus %u
Icon=sonobus
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Mixer;
Keywords=live;online;music;conference;
MimeType=x-scheme-handler/sonobus
EOT

                #                tee /home/$LOGINUSR/Skrivbord/sonobus.desktop >/dev/null <<EOT
                #[Desktop Entry]
                #Name=SonoBus
                #Comment=High Quality Network Audio Streaming
                #GenericName=Network Audio Streaming Software
                #Exec=sonobus %u
                #Icon=sonobus
                #Terminal=false
                #Type=Application
                #Categories=AudioVideo;Audio;Mixer;
                #Keywords=live;online;music;conference;
                #MimeType=x-scheme-handler/sonobus

                #EOT
                clear
                whiptail --title "SonoBus Installation" --msgbox "SonoBus är nu installerad och klar att använda." 15 78
                installloop=0
            done
        else
            clear
        fi
    }

    function MainHelp {
        whiptail --textbox --scrolltext $RUNFOLDER/mainhelp.txt 20 80
    }

    while true; do
        CHOICE=$(
            whiptail --title "Välj vad du vill göra" --menu "Välj vad du vill göra, för specifika datorer, se under Mera saker." 20 100 10 \
                "1)" "Installera VNC" \
                "2)" "Installera Rivendell" \
                "3)" "Installera Jack Audio" \
                "4)" "Installera Jack Mixer" \
                "5)" "Installera SonoBus" \
                "6)" "Uppdatera Rivendell" \
                "7)" "Skapa Ljudkort Script" \
                "8)" "Mera Saker" \
                "9)" "Hjälp & Information" \
                "10)" "Avsluta" 3>&2 2>&1 1>&3
        )
        result=$(whoami)
        case $CHOICE in
        "1)")
            installVNC
            ;;
        "2)")
            installRivendell
            ;;
        "3)")
            installJack
            ;;
        "4)")
            installJackMixer
            ;;
        "5)")
            installSonoBus
            ;;
        "6)")
            updateRivendell
            ;;
        "7)")
            createSoundcard
            ;;
        "8)")
            otherStuff
            ;;
        "9)")
            MainHelp
            ;;
        "10)")
            exit
            ;;
        esac
        #whiptail --msgbox "$result" 20 78
    done
    exit
else
    exit
fi
