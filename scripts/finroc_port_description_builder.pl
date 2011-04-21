#!/usr/bin/perl -w

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
# 
#----------------------------------------------------------------------
# \file    finroc_port_description_builder.pl
#
# \author  Max Reichardt
#
# \date    2011-04-21
#
# Script to auto-generate port descriptions for finroc modules in the build process.
# It operates on doxygen perlmod output.
#
# It creates a .cpp file with descriptions for all modules and groups that contain ports.
#----------------------------------------------------------------------

use strict;
use DoxyDocs;

my $classes = $::doxydocs->{classes};
my $files = $::doxydocs->{files};

# generate header comment
print "// this is a -*- C++ -*- file\n";
print "/*\n * This file was generated from the source file(s)";
foreach my $file (@$files) {
    print "\n * ";
    print $file->{name};
}
print "\n * using finroc_port_description_builder.pl.";
print "\n * This code is released under the same license as the source files.\n */\n\n";

# includes, namespace
print "#include \"core/structure/tStructureElementRegister.h\"\n\n";
print "using finroc::core::structure::tStructureElementRegister;\n\n";
print "namespace finroc\n{\nnamespace generated\n{\n\n";

# generate code for names
print "int Init()\n{\n";
print "  std::vector<util::tString> names;\n";
foreach my $class (@$classes) {
	print "\n  // class $class->{name}\n";
    print "  names.clear();\n";
	my $members = $class->{public_members}->{members};
	foreach my $member (@$members) {
		if ($member->{kind} eq 'variable' && $member->{static} eq 'no') {
			my $type = $member->{type};
			my @typesplit = split(/</, $type);
			$type = $typesplit[0]; # remove any template arguments
			if ($type eq 'tInput' || $type eq 'tOutput' || $type eq 'tSensorInput' || $type eq 'tSensorOutput' || $type eq 'tControllerInput' || $type eq 'tControllerOutput' || $type eq 'tParameter') {
				
				# copied from MCA2-KL description builder
			    my @words = split ("_", $member->{name});
				my $w0 = $words[0];
				if (($w0 eq 'si' && $type eq 'tSensorInput') || ($w0 eq 'so' && $type eq 'tSensorOutput') || ($w0 eq 'ci' && $type eq 'tControllerInput') || ($w0 eq 'co' && $type eq 'tControllerOutput') || ($w0 eq 'par' && $type eq 'tParameter')) {
					shift(@words);
				}
			    @words = map lc, @words;
	    		@words = map ucfirst, @words;
			    my $name = join (" ", @words);
				print "  names.push_back(\"$name\");\n"
			}
		}
	}
	
	print "  tStructureElementRegister::AddPortNamesForModuleType(\"$class->{name}\", names);\n";
}
print "\n  return 0;\n";
print "}\n\n";
print "int cINIT = Init();\n\n";
print "}\n}\n";

