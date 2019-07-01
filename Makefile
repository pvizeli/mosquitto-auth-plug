# Load our module (and misc) configuration from config.mk
# It also contains MOSQUITTO_SRC
include config.mk

BE_CFLAGS =
BE_LDFLAGS =
BE_LDADD =
BE_DEPS =
OBJS = src/auth-plug.o src/base64.o src/pbkdf2-check.o src/log.o src/envs.o src/hash.o src/be-psk.o src/backends.o src/cache.o

BACKENDS =
BACKENDSTR =

ifneq ($(BACKEND_CDB),no)
	BACKENDS += -DBE_CDB
	BACKENDSTR += CDB

	CDBDIR = contrib/tinycdb-0.78
	CDB = $(CDBDIR)/cdb
	CDBINC = $(CDBDIR)/
	CDBLIB = $(CDBDIR)/libcdb.a
	BE_CFLAGS += -I$(CDBINC)/
	BE_LDFLAGS += -L$(CDBDIR)
	BE_LDADD += -lcdb
	BE_DEPS += $(CDBLIB)
	OBJS += src/be-cdb.o
endif

ifneq ($(BACKEND_MYSQL),no)
	BACKENDS += -DBE_MYSQL
	BACKENDSTR += MySQL

	BE_CFLAGS += `mysql_config --cflags`
	BE_LDADD += `mysql_config --libs`
	OBJS += src/be-mysql.o
endif

ifneq ($(BACKEND_SQLITE),no)
	BACKENDS += -DBE_SQLITE
	BACKENDSTR += SQLite

	BE_LDADD += -lsqlite3
	OBJS += src/be-sqlite.o
endif

ifneq ($(BACKEND_REDIS),no)
	BACKENDS += -DBE_REDIS
	BACKENDSTR += Redis

	BE_CFLAGS += -I/usr/local/include/hiredis
	BE_LDFLAGS += -L/usr/local/lib
	BE_LDADD += -lhiredis
	OBJS += src/be-redis.o
endif

ifeq ($(BACKEND_MEMCACHED),yes)
	BACKENDS += -DBE_MEMCACHED
	BACKENDSTR += Memcached

	BE_CFLAGS += -I/usr/local/include/libmemcached
	BE_LDFLAGS += -L/usr/local/lib
	BE_LDADD += -lmemcached
	OBJS += src/be-memcached.o
endif

ifneq ($(BACKEND_POSTGRES),no)
	BACKENDS += -DBE_POSTGRES
	BACKENDSTR += PostgreSQL

	BE_CFLAGS += -I`pg_config --includedir`
	BE_LDADD += -L`pg_config --libdir` -lpq
	OBJS += src/be-postgres.o
endif

ifneq ($(BACKEND_LDAP),no)
	BACKENDS += -DBE_LDAP
	BACKENDSTR += LDAP

	BE_LDADD += -lldap -llber
	OBJS += src/be-ldap.o
endif

ifneq ($(BACKEND_HTTP), no)
	BACKENDS+= -DBE_HTTP
	BACKENDSTR += HTTP

	BE_LDADD += -lcurl
	OBJS += src/be-http.o
endif

ifneq ($(BACKEND_JWT), no)
	BACKENDS+= -DBE_JWT
	BACKENDSTR += JWT

	BE_LDADD += -lcurl
	OBJS += src/be-jwt.o
endif

ifneq ($(BACKEND_MONGO), no)
	BACKENDS+= -DBE_MONGO
	BACKENDSTR += MongoDB

	BE_CFLAGS += -I/usr/local/include/
	BE_CFLAGS +=`pkg-config --cflags-only-I libmongoc-1.0 libbson-1.0`
	BE_LDFLAGS +=`pkg-config --libs-only-L libbson-1.0 libmongoc-1.0`
	BE_LDFLAGS += -L/usr/local/lib
	BE_LDADD += -lmongoc-1.0 -lbson-1.0
	OBJS += src/be-mongo.o
endif

ifneq ($(BACKEND_FILES), no)
	BACKENDS+= -DBE_FILES
	BACKENDSTR += Files

	OBJS += src/be-files.o
endif

ifeq ($(origin SUPPORT_DJANGO_HASHERS), undefined)
	SUPPORT_DJANGO_HASHERS = no
endif

ifneq ($(SUPPORT_DJANGO_HASHERS), no)
	CFG_CFLAGS += -DSUPPORT_DJANGO_HASHERS
endif

OSSLINC = -I$(OPENSSLDIR)/include
OSSLIBS = -L$(OPENSSLDIR)/lib -lcrypto

CFLAGS := $(CFG_CFLAGS)
CFLAGS += -I$(MOSQUITTO_SRC)/src/
CFLAGS += -I$(MOSQUITTO_SRC)/lib/
ifneq ($(OS),Windows_NT)
	CFLAGS += -fPIC -Wall -Werror
endif
CFLAGS += $(BACKENDS) $(BE_CFLAGS) -I$(MOSQ)/src -DDEBUG=1 $(OSSLINC)

LDFLAGS := $(CFG_LDFLAGS)
LDFLAGS += $(BE_LDFLAGS) -L$(MOSQUITTO_SRC)/lib/
# LDFLAGS += -Wl,-rpath,$(../../../../pubgit/MQTT/mosquitto/lib) -lc
# LDFLAGS += -export-dynamic
LDADD = $(BE_LDADD) $(OSSLIBS) -lmosquitto

all: printconfig auth-plug.so np

printconfig:
	@echo "Selected backends:         $(BACKENDSTR)"
	@echo "Using mosquitto source dir: $(MOSQUITTO_SRC)"
	@echo "OpenSSL install dir:        $(OPENSSLDIR)"
	@echo
	@echo "If you changed the backend selection, you might need to 'make clean' first"
	@echo
	@echo "CFLAGS:  $(CFLAGS)"
	@echo "LDFLAGS: $(LDFLAGS)"
	@echo "LDADD:   $(LDADD)"
	@echo



auth-plug.so : $(OBJS) $(BE_DEPS)
	$(CC) $(CFLAGS) $(LDFLAGS) -fPIC -shared -o $@ $(OBJS) $(BE_DEPS) $(LDADD)

be-redis.o: src/be-redis.c src/be-redis.h src/log.h src/hash.h src/envs.h Makefile
be-memcached.o: src/be-memcached.c src/be-memcached.h src/log.h src/hash.h src/envs.h Makefile
be-sqlite.o: src/be-sqlite.c src/be-sqlite.h Makefile
auth-plug.o: src/auth-plug.c src/be-cdb.h src/be-mysql.h src/be-sqlite.h Makefile src/cache.h
be-psk.o: src/be-psk.c src/be-psk.h Makefile
be-cdb.o: src/be-cdb.c src/be-cdb.h Makefile
be-mysql.o: src/be-mysql.c src/be-mysql.h Makefile
be-ldap.o: src/be-ldap.c src/be-ldap.h Makefile
be-sqlite.o: src/be-sqlite.c src/be-sqlite.h Makefile
pbkdf2-check.o: src/pbkdf2-check.c src/base64.h Makefile
base64.o: src/base64.c src/base64.h Makefile
log.o: src/log.c src/log.h Makefile
envs.o: src/envs.c src/envs.h Makefile
hash.o: src/hash.c src/hash.h src/uthash.h Makefile
be-postgres.o: src/be-postgres.c src/be-postgres.h Makefile
cache.o: src/cache.c src/cache.h src/uthash.h Makefile
be-http.o: src/be-http.c src/be-http.h Makefile src/backends.h
be-jwt.o: src/be-jwt.c src/be-jwt.h Makefile src/backends.h
be-mongo.o: src/be-mongo.c src/be-mongo.h Makefile
be-files.o: src/be-files.c src/be-files.h Makefile
backends.o: src/backends.c src/backends.h Makefile

np: src/np.c src/base64.o
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@ $(OSSLIBS)

$(CDBLIB):
	(cd $(CDBDIR); make libcdb.a cdb )

pwdb.cdb: pwdb.in
	$(CDB) -c -m  pwdb.cdb pwdb.in
clean :
	rm -f *.o *.so np
	(cd contrib/tinycdb-0.78; make realclean )

config.mk:
	@echo "Please create your own config.mk file"
	@echo "You can use config.mk.in as base"
	@false
