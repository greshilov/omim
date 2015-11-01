#-------------------------------------------------
#
# Project created by QtCreator 2015-03-27T13:21:18
#
#-------------------------------------------------


TARGET = opening_hours
TEMPLATE = lib
CONFIG += staticlib

ROOT_DIR = ../..

include($$ROOT_DIR/common.pri)

HEADERS += osm_time_range.hpp \
           osm_parsers.hpp \
           osm_parsers_terminals.hpp \
           parse.hpp \
           rules_evalustion.hpp \
           rules_evalustion_private.hpp \

SOURCES += osm_time_range.cpp \
           parse.cpp \
           rules_evaluation.cpp \
