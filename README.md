You’ve understood the main parts. Here is the full picture, so you can see what’s missing.

## What you got right

- You create 3 users, one per role.
- You don’t touch root.
- You don’t edit `/etc/sudoers` directly. You add your own files in `/etc/sudoers.d/`, which sudo reads automatically.
- You need a shared directory.

## What’s missing

### 1. The shared directory has two parts, not one

- `/srv/shared`: admin and developer can write, deploy can only read, everyone else gets nothing. It uses setgid plus ACLs.
- `/srv/scratch`: anyone can write, but you can only delete your own files. It uses the sticky bit.

### 2. The password policy

- Passwords expire after N days (`chage`).
- Accounts lock after repeated failed logins (PAM).

### 3. SSH, which you said you don’t have yet

You need to install it first:

```bash
apt install openssh-server
```

Then each user gets a key, you confirm key login works, and only after that do you disable password login. If you do it in the other order, you lock yourself out.

### 4. verify.sh

A script that tries forbidden actions as each user and prints `PASS` if they are denied. It exits with a non-zero code if any check fails.

### 5. The repo

`README.md`, `sudoers.d/` (copies of your files), and `verify.sh`.

## The key idea: who can do what

| | Sudo | Shared dir | Install packages | Manage users |
|---|---|---|---|---|
| **admin** | everything | read + write | yes | yes |
| **developer** | only restart your service | read + write | no | no |
| **deploy** | only restart your service | read only | no | no |

Think of it as three layers of control:

1. **sudo** decides what commands each user can run as root.
2. **File permissions and ACLs** decide who can touch the shared directory.
3. **SSH** decides how users get into the server at all.

The whole project is about setting these up so each role gets exactly its row in the table, and nothing more.

## Your order of work

1. Create the 3 users and the group.
2. Write the sudoers files (this is the hardest part).
3. Set up the password policy.
4. Create the two directories.
5. Install and configure SSH.
6. Write `verify.sh` (add checks as you finish each step).
7. Write the README.

## Start now

Step 1 takes 5 minutes. Run this in your VM as root, and replace the names if you want:

```bash
groupadd team
useradd -m -s /bin/bash -G team,sudo alice    # admin
useradd -m -s /bin/bash -G team bob           # developer
useradd -m -s /bin/bash carol                 # deploy
passwd alice; passwd bob; passwd carol
id alice; id bob; id carol
```

Notice that only alice is in the sudo group, because that is how she gets full admin rights. Bob and carol are not, so they start with nothing.

Run these and send me the output of the three `id` commands. Then we move to the sudoers part.
