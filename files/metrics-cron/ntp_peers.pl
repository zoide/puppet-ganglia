#!/usr/bin/env perl
# Plugin to monitor offsets to multiple NTP peers.
# NB currently only works for IPv4 peers
#
# (c)2008 Chris Hastie: chris (at) oak (hyphen) wood (dot) co (dot) uk
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Change log
# v1.0.0    2008-07-21        Chris Hastie
# initial release
# v1.1.0 2009-05-29  Udo.Waechter@uos.de - adapted for ganglia 
#

use strict;
use Socket;

my $NTPQ = $ENV{ntpq} || "ntpq";
my $COMMAND    =      "$NTPQ -np";

my $statedir = $ENV{statedir} || '/var/tmp/';
my $statefile = "$statedir/ntp_peers.state";

my %peers;

chomp(my $gmetric=`which gmetric`);
exit 0 if ($? != 0);

# retrieve cached list of IPs and hostnames
if (-f "$statefile") {
    open (IN, "$statefile") or exit 4;
    while (<IN>) {
      if (/^([0-9\.]+):(.*)$/) {
        $peers{$1}{'name'} = $2;
      }
    }
    close IN;
}


# do custom IP lookups
for my $key (map {/^hostname_(.+)/} keys %ENV) {
    my $ip = &desanitize_field($key);
    $peers{$ip}{'name'} = $ENV{"hostname_$key"}
}

# get data from ntpq
open(SERVICE, "$COMMAND |")
  or die("Could not execute '$COMMAND': $!");

while (<SERVICE>) {
    if (/^[-+*#](\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(\s+\S+){7}\s+(\S+)/) {
      my $name  = &lookupname($1);
      $peers{$1}{'value'} = $3;      
    }
}
close(SERVICE);

# config
if ($ARGV[0] and $ARGV[0] eq 'config') {
  print "graph_title NTP peer offsets\n";
  print "graph_args --base 1000\n";
  print "graph_vlabel ms\n";
  print "graph_category ntp\n";
  print "graph_info Offset (in ms) to the server's NTP peers\n";
  print "graph_order ";
  foreach my $key (sort by_name keys %peers) {
    print &sanitize_field($peers{$key}{'name'}) . " ";
  }
  print "\n";
  foreach my $peer (keys %peers) {
    print &sanitize_field($peers{$peer}{'name'}) . ".label " . $peers{$peer}{'name'} . "\n";
  }
  exit 0;
}

# send output
foreach my $peer (keys %peers) {
  my $value = &getpeeroffset($peer);
  system("$gmetric --name=\"NTP offset $peers{$peer}{'name'}\" --value=$value --tmax=1800 --dmax=30000 --type=int16 --units=\"Milliseconds\"");
}

# save list of peer IPs and hostnames
if(-l $statefile) {
    die("$statefile is a symbolic link, refusing to touch it.");
}               
open (OUT, ">$statefile") or exit 4;
foreach my $i (keys %peers) {
  print OUT "$i:" . $peers{$i}{'name'} .  "\n";
}
close OUT;

# sorts by hostname
sub by_name {
    return $peers{$a}{'name'} cmp $peers{$b}{'name'};
}

# create a valid munin field name from the hostname
sub sanitize_field () {
  my $field = shift;
  
  # replace illegal characters with an underscore
  $field =~ s/[^A-Za-z0-9_]/_/g;
  # prepend an underscore if name starts with a number
  $field =~ s/^([^A-Za-z_])/_$1/;
  
  # truncate to 19 characters
  if (length($field) > 19) {
    $field = substr($field, 0, 19);
  }
  return $field
}

# get an IP address from the underscore escaped
# value of env.hostname_<key>
sub desanitize_field () {
  my $field = shift;
  $field =~ s/_/\./g;
  return $field
}

# lookup hostnames
sub lookupname () {
  my $ip = shift;
  # have we already got it?
  if ($peers{$ip}{'name'}) {
    return $peers{$ip}{'name'};    
  }
  # else look it up
  my $iaddr = inet_aton($ip); 
  my $name  = gethostbyaddr($iaddr, AF_INET) || $ip; 
  # add to cache
  $peers{$ip}{'name'} = $name;
  return $name;
}

# returns the offset, or U if it is undefined
sub getpeeroffset() {
  my $ip = shift;
  my $rtn = 'U';
  if (exists($peers{$ip}{'value'})) {
    $rtn = $peers{$ip}{'value'};
  }
  return $rtn
}

=pod

=head1 Description

ntp_peers - A munin plugin to monitor offsets to multiple NTP peers and
graph them on a single graph

=head1 Parameters understood:

  config   (required)
  autoconf (optional - used by munin-node-configure)

=head1 Configuration variables:

All configuration parameters are optional

  ntpq            - path to ntpq program
  statedir        - directory in which to place state file
  hostname_<key>  - override hostname for peer <key>. <key> is
                    an IPv4 address with dots replaced by underscores.
                    Useful for reference clocks, eg
                    env.hostname_127_127_43_0  .GPS.

=head1 Known issues

ntp_peers will not monitor IPv6 peers

=cut
