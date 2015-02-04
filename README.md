# Percona Server 5.5

## Usage

### Disposable database

Data is stored in `/var/lib/mysql`, which can be optionally mounted to the host.
If you do not mount it, your data will live and die with the container.
No root password is set when you do not mount the data directory, so you can
connect to mysql like so:

```bash
docker run -d freshbooks/percona:5.5
docker run -it \
  --link container_name:mysql \
  --rm \
  freshbooks/percona:5.5 \
  sh -c 'exec mysql -h"$MYSQL_PORT_3306_TCP_ADDR" -P"$MYSQL_PORT_3306_TCP_PORT" -uroot'
```

### Persisting database

To persist data beyond the life of the container, mount a directory from the
host to `/var/lib/mysql` in the container. If you do this, you must either
define a root password, or explicitly say you do not want one:

```bash
docker run -dv /tmp/mysql:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=passwerd \
  freshbooks/percona:5.5
docker run -it \
  --link container_name:mysql \
  --rm \
  freshbooks/percona:5.5 \
  sh -c 'exec mysql -h"$MYSQL_PORT_3306_TCP_ADDR" -P"$MYSQL_PORT_3306_TCP_PORT" -uroot -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD'
```

### Default Configuration

Configuration for mysql can be overridden by mounting a directory to
`/etc/mysql/conf.d`.

## Environment Variables

The MySQL image uses several environment variables which are easy to miss. While
not all the variables are required, they may significantly aid you in using the
image.

### `MYSQL_ROOT_PASSWORD`, `MYSQL_ALLOW_EMPTY_PASSWORD`

`MYSQL_ROOT_PASSWORD` is the one environment variable that is required for you to use the MySQL
image. This environment variable should be what you want to set the root
password for MySQL to. In the above example, it is being set to
`passwerd`. Alternately, you can set `MYSQL_ALLOW_EMPTY_PASSWORD` to `true`.

### `MYSQL_USER`, `MYSQL_PASSWORD`

These optional environment variables are used in conjunction to set both a MySQL
user and password, which will subsequently be granted all permissions for the
database specified by the optional `MYSQL_DATABASE` variable. Note that if you
only have one of these two environment variables, then neither will actually do
anything - these two are meant to be used in conjunction with one another. When
these variables are used, it will create a new user with the given password in
the MySQL database - there is no need to specify `MYSQL_USER` with `root`, as
the `root` user already exists in the default MySQL and the password is
controlled by `MYSQL_ROOT_PASSWORD`.

### `MYSQL_DATABASE`

This optional environment variable denotes the name of a database to create. If
a user/password was supplied (via the `MYSQL_USER` and `MYSQL_PASSWORD`
environment variables) then that user account will be granted (`GRANT ALL`)
access to this database.

