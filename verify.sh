#!/bin/bash
# verify.sh - simple version. Run as root: sudo ./verify.sh

PASS=0
FAIL=0
cd /tmp

# ---------- SUDO ----------
echo "== sudo =="

if sudo -l -U admin1 | grep -q "ALL) ALL"; then
    echo "PASS: admin1 has full sudo"; PASS=$((PASS+1))
else
    echo "FAIL: admin1 has full sudo"; FAIL=$((FAIL+1))
fi

if sudo -l -U dev1 | grep -Eq "\) (NOPASSWD: )?ALL$"; then
    echo "FAIL: dev1 has full sudo"; FAIL=$((FAIL+1))
else
    echo "PASS: dev1 has no full sudo"; PASS=$((PASS+1))
fi

if sudo -l -U deploy1 | grep -Eq "\) (NOPASSWD: )?ALL$"; then
    echo "FAIL: deploy1 has full sudo"; FAIL=$((FAIL+1))
else
    echo "PASS: deploy1 has no full sudo"; PASS=$((PASS+1))
fi

if sudo -u dev1 sudo -n -l /usr/bin/systemctl restart myservice > /dev/null 2>&1; then
    echo "PASS: dev1 can restart myservice"; PASS=$((PASS+1))
else
    echo "FAIL: dev1 can restart myservice"; FAIL=$((FAIL+1))
fi

if sudo -u deploy1 sudo -n -l /usr/bin/systemctl restart myservice > /dev/null 2>&1; then
    echo "PASS: deploy1 can restart myservice"; PASS=$((PASS+1))
else
    echo "FAIL: deploy1 can restart myservice"; FAIL=$((FAIL+1))
fi

if sudo -u dev1 sudo -n -l /usr/bin/systemctl restart ssh > /dev/null 2>&1; then
    echo "FAIL: dev1 can restart ssh"; FAIL=$((FAIL+1))
else
    echo "PASS: dev1 cannot restart ssh"; PASS=$((PASS+1))
fi

if sudo -u dev1 sudo -n -l /usr/bin/apt > /dev/null 2>&1; then
    echo "FAIL: dev1 can use apt"; FAIL=$((FAIL+1))
else
    echo "PASS: dev1 cannot use apt"; PASS=$((PASS+1))
fi

if sudo -u deploy1 sudo -n -l /usr/sbin/adduser > /dev/null 2>&1; then
    echo "FAIL: deploy1 can use adduser"; FAIL=$((FAIL+1))
else
    echo "PASS: deploy1 cannot use adduser"; PASS=$((PASS+1))
fi

# ---------- PROJECT DIRECTORY ----------
echo "== /srv/project =="

if sudo -u dev1 sh -c 'echo dev > /srv/project/test.txt' 2>/dev/null; then
    echo "PASS: dev1 creates a file"; PASS=$((PASS+1))
else
    echo "FAIL: dev1 creates a file"; FAIL=$((FAIL+1))
fi

if sudo -u admin1 sh -c 'echo admin >> /srv/project/test.txt' 2>/dev/null; then
    echo "PASS: admin1 edits dev1's file"; PASS=$((PASS+1))
else
    echo "FAIL: admin1 edits dev1's file"; FAIL=$((FAIL+1))
fi

if sudo -u deploy1 cat /srv/project/test.txt > /dev/null 2>&1; then
    echo "PASS: deploy1 reads the file"; PASS=$((PASS+1))
else
    echo "FAIL: deploy1 reads the file"; FAIL=$((FAIL+1))
fi

if sudo -u deploy1 sh -c 'echo x >> /srv/project/test.txt' 2>/dev/null; then
    echo "FAIL: deploy1 wrote to the file"; FAIL=$((FAIL+1))
else
    echo "PASS: deploy1 cannot write"; PASS=$((PASS+1))
fi

if sudo -u deploy1 touch /srv/project/deploy.txt 2>/dev/null; then
    echo "FAIL: deploy1 created a file"; FAIL=$((FAIL+1))
else
    echo "PASS: deploy1 cannot create a file"; PASS=$((PASS+1))
fi

if sudo -u usertest ls /srv/project > /dev/null 2>&1; then
    echo "FAIL: usertest can read /srv/project"; FAIL=$((FAIL+1))
else
    echo "PASS: usertest cannot read /srv/project"; PASS=$((PASS+1))
fi

rm -f /srv/project/test.txt /srv/project/deploy.txt

# ---------- SCRATCH DIRECTORY ----------
echo "== /srv/scratch =="

if [ "$(stat -c %A /srv/scratch)" = "drwxrwxrwt" ]; then
    echo "PASS: scratch has sticky bit"; PASS=$((PASS+1))
else
    echo "FAIL: scratch has sticky bit"; FAIL=$((FAIL+1))
fi

sudo -u dev1 touch /srv/scratch/dev1.txt

if sudo -u deploy1 rm /srv/scratch/dev1.txt 2>/dev/null; then
    echo "FAIL: deploy1 deleted dev1's file"; FAIL=$((FAIL+1))
else
    echo "PASS: deploy1 cannot delete dev1's file"; PASS=$((PASS+1))
fi

if sudo -u dev1 rm /srv/scratch/dev1.txt 2>/dev/null; then
    echo "PASS: dev1 deletes own file"; PASS=$((PASS+1))
else
    echo "FAIL: dev1 deletes own file"; FAIL=$((FAIL+1))
fi

# ---------- SSH ----------
echo "== ssh =="

if sshd -T | grep -q "^passwordauthentication no"; then
    echo "PASS: password login disabled"; PASS=$((PASS+1))
else
    echo "FAIL: password login disabled"; FAIL=$((FAIL+1))
fi

if sshd -T | grep -q "^pubkeyauthentication yes"; then
    echo "PASS: key login enabled"; PASS=$((PASS+1))
else
    echo "FAIL: key login enabled"; FAIL=$((FAIL+1))
fi

# ---------- RESULT ----------
echo
echo "PASS=$PASS FAIL=$FAIL"

if [ $FAIL -eq 0 ]; then
    exit 0
else
    exit 1
fi