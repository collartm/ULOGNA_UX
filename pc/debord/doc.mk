#!/usr/bin/make -f
#  @(#)  Automatically produced by $Id: genmk.pl 891 2015-02-16 10:30:55Z bdav $ from $Id: templatedirdoc.mk 643 2007-05-02 05:05:14Z bdav $
#
# ORACLE     Copyright SYDEL  LORIENT-FRANCE
#
include $(BUILD_TOOLS)/doc/phony.mk

subdirs= doc

.PHONY: $(subdirs)

_install-as: target_name=_install-as
_install-doc: target_name=_install-doc

_install-as _install-doc: $(subdirs)

$(subdirs):
	$(MAKE) -C $@ $(target_name)