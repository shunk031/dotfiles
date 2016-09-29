#!/usr/bin/python
# -*- coding: utf-8 -*-

import hauth
name, passwd = hauth.get_user_properties(from_pit=True)
bool = hauth.hauthorize(name, passwd)
print(bool)
