# Percona Server 5.5

## Default Configuration

The MySQL default configuration can be overriden by exporting the /etc/mysql/conf.d/ directory

## Environment Variables

The MySQL image uses several environment variables which are easy to miss. While
not all the variables are required, they may significantly aid you in using the
image.

### `MYSQL_ROOT_PASSWORD`

This is the one environment variable that is required for you to use the MySQL
image. This environment variable should be what you want to set the root
password for MySQL to. In the above example, it is being set to
"mysecretpassword".

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

