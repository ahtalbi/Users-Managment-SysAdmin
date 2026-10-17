![intro](./assets/A_README_intro.png)

# Structure Of Readme File

01 — Project Overview
02 — System Prerequisites
03 — Users and Role Groups
04 — Sudo Privileges Configuration
05 — Password and Account Security
    05.1 — Password Expiration Management (chage)
    05.2 — Login Failure Protection (PAM)
06 — Shared Storage and Directory Management
    06.1 — Project Workspace
    06.2 — Temporary Workspace
    06.3 — Permission Mechanisms Comparison
07 — SSH Service Security
08 — Verification Script
09 — Repository Structure
10 — Conclusion

# OverView
This project is based on the [Linux project](https://github.com/ahtalbi/Linux-Sysadmin.git). We continue on the same Debian server that was built there, including the systemd service that was created in that project. The service is the one the roles are allowed to restart.

## Goal
A server where everyone logs in as root is not administered, it is only switched on. The goal is to give each person **exactly the access their role needs, and nothing more** (the principle of least privilege), and then to **prove it with a script**.

## What we have to build
- **SSH keys:** one key per user, and password login disabled.
- **Groups and ACLs:** a shared project folder where the writers group can edit and the readers group can only read.
- **sudo rules:** one file per role in `/etc/sudoers.d/`, limited to specific commands.
- **Password policy:** passwords expire (`chage`) and accounts lock after repeated failures (`pam_faillock`).
- **Scratch directory:** a shared folder where users can delete only their own files (sticky bit).
- **Verification script:** `verify.sh` tries every forbidden action and checks that it is denied.

# Users and Role Groups

Here we initialized the users and added one group for every role, as shown in the image:

![users groups creation](./assets/USERS_GROUPS_creation.png)

## The team

| Role | User | Role group |
|---|---|---|
| admin | `admin1` | `admin` |
| developer | `dev1` | `developer` |
| deploy | `deploy1` | `deploy` |

## Add users to theire groups

```bash
adduser admin1 admin
adduser dev1 developer
adduser deploy1 deploy
```
## Check The groups

```bash
id admin1
id dev1
id deploy1
getent group admin developer deploy
```

### Sudo Configuration

Privileges are not written in `/etc/sudoers`. Each role group gets its own file in `/etc/sudoers.d/`, and every file is checked with `visudo`.

| File | Content |
|---|---|
| `/etc/sudoers.d/admin` | `%admin ALL=(ALL:ALL) ALL` |
| `/etc/sudoers.d/developer` | `%developer ALL=(root) NOPASSWD: /usr/bin/systemctl restart myservice` |
| `/etc/sudoers.d/deploy` | `%deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart myservice` |

Created with:

    visudo /etc/sudoers.d/admin
    visudo /etc/sudoers.d/developer
    visudo /etc/sudoers.d/deploy

Least-privilege rules:

- Privileges are granted to groups, never directly to users.
- Only `admin1` has full privileges, through `%admin ALL=(ALL:ALL) ALL`.
- Nobody is in the `sudo` group: on Debian it already grants `ALL=(ALL:ALL) ALL` and would override any scoped rule.
- Command-scoped rules only: developer and deploy can run only `/usr/bin/systemctl restart myservice`.


## to run sudo you must install it
```
apt install sudo
```

Verify with:

    sudo -l -U admin1
    sudo -l -U dev1
    sudo -l -U deploy1

Only `admin1` has full privileges. Any other role showing them is a policy failure.

![Users permessions](./assets/USERS_permessions.png)

## to test acces the users with
```
su - admin1 ## then any command should work
su - dev1 ## then only the restart should work
```

