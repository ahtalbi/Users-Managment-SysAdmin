![intro](./assets/A_README_intro.png)

# OverView

This project is based on the [Linux project](https://github.com/ahtalbi/Linux-Sysadmin.git). We continue on the same Debian server that was built there, including the systemd service that was created in that project. The service is the one the roles are allowed to restart.

## Goal

A server where everyone logs in as root is not administered, it is only switched on. The goal is to give each person **exactly the access their role needs, and nothing more** (the principle of least privilege), and then to **prove it with a script**.

## The team

| Role | User | Group | Can | Cannot |
|---|---|---|---|---|
| admin | `admin1` | `projectteam` | manage users, install packages, restart any service, read and write the project folder | nothing is restricted |
| developer | `dev1` | `projectteam` | read and write the project folder, restart only the service | install packages, manage users |
| deploy | `deploy1` | `project-readers` | restart only the service, read the project folder | write to the project folder, install packages, manage users |

## What we build

- **SSH keys:** one key per user, and password login disabled.
- **Groups and ACLs:** a shared project folder where the writers group can edit and the readers group can only read.
- **sudo rules:** one file per role in `/etc/sudoers.d/`, limited to specific commands.
- **Password policy:** passwords expire (`chage`) and accounts lock after repeated failures (`pam_faillock`).
- **Scratch directory:** a shared folder where users can delete only their own files (sticky bit).
- **Verification script:** `verify.sh` tries every forbidden action and checks that it is denied.

## What to understand before starting

- **Least privilege:** give the minimum access needed for the job.
- **Users and groups:** a group is a list of users sharing the same rights. Access is managed by adding or removing people from groups.
- **File permissions:** `rwx`, and the fact that on a folder `x` means "enter" and `w` means "create and delete inside".
- **Special bits:** setgid makes new files inherit the folder's group, and the sticky bit stops users from deleting each other's files.
- **ACLs:** extra rules for a file or folder when owner, group and others are not enough. A default ACL is a template for new files.
- **sudo:** lets a user run specific commands as root. On Debian, the `sudo` group gives full root, so only `admin1` may be in it.
- **PAM:** the system that runs on every login, where the lockout rule lives.
- **SSH keys:** the private key stays with the user, the public key goes on the server. Test the key before disabling passwords.

# Configuring PAM

To configure PAM, we need to change 3 files.

## 1 - /etc/security/faillock.conf

Uncomment these lines (remove the `#` at the start):

```
deny = 3
unlock_time = 1200
fail_interval = 900
```

Explanation:

```
deny = 3: lock after 3 failed attempts
unlock_time = 1200: locked for 1200 seconds (20 minutes)
fail_interval = 900: the 3 failures must happen within 15 minutes (adjust if your spec says otherwise)
```

## 2 - /etc/pam.d/common-auth

First of all, be careful: if you make a mistake in this file, your system can lock you out. So before editing it, keep a second terminal open (with a root session) in case something goes wrong, and make a backup copy of the file:

```
sudo cp /etc/pam.d/common-auth /etc/pam.d/common-auth.bak
```

![PAMcommonauth](./assets/PAM-commun-auth.png)

## 3 - /etc/pam.d/common-account

It should look something like this:

![PAMFaillock](./assets/PAM-faillock.png)

## Checking and resetting failed attempts

To check failed attempts and get more details, use the `faillock` command:

```
faillock
faillock --user username
```

To reset a user who has been locked out, run:

```
faillock --user username --reset
```

# Configuring the Shared Directory

The best way to configure a folder is to use **2 groups** instead of setting permissions for every user one by one with ACLs (Access Control Lists). Once the groups exist, I only add or remove users from the groups, and the access changes by itself. Each group has a role.

| Group | Role | Rights on the folder | Members |
|---|---|---|---|
| `projectteam` | writers | read, write, enter (`rwx`) | `admin1`, `dev1` |
| `project-readers` | readers | read, enter (`r-x`) | `deploy1` |

Everyone else has no access.

## 1. Create the groups and add the users

```bash
addgroup projectteam
addgroup project-readers
adduser admin1 projectteam
adduser dev1 projectteam
adduser deploy1 project-readers
```

## 2. Create the folder

```bash
mkdir /srv/project
```

## 3. Give the folder to the writers group

```bash
chown root:projectteam /srv/project
```

## 4. Set the base permissions

```bash
chmod 2770 /srv/project
```

- `2` = setgid: new files get the group `projectteam`
- `7` = owner: read, write, enter
- `7` = group: read, write, enter
- `0` = others: nothing

## 5. Give the readers group access (ACL)

```bash
setfacl -m g:project-readers:rx /srv/project
```

`-m` means "add this rule". `g:project-readers:rx` means "the group `project-readers` gets read and enter".

## 6. Make new files follow the same rules (default ACL)

```bash
setfacl -d -m u::rwx /srv/project
setfacl -d -m g::rwx /srv/project
setfacl -d -m o::--- /srv/project
setfacl -d -m g:project-readers:rx /srv/project
```

`-d` means "default": a template copied to every new file or folder.

- `u::rwx`: the creator of the file can do everything
- `g::rwx`: the writers group can edit the file (no `chmod` needed)
- `o::---`: others get nothing
- `g:project-readers:rx`: the readers group can read the file

## 7. Check

```bash
ls -ld /srv/project
getfacl /srv/project
```
