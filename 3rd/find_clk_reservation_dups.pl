#!/usr/bin/perl -w

# usage: $0 <dcp>
# returns number of dups that exist

use strict;

my $verbose = 0;

my $dcp = shift;
my $tmpdir = cmd('mktemp -t -d clkresdup.XXXXX');
print "TMPDIR: $tmpdir\n" if $verbose;
cmd("unzip -d $tmpdir $dcp '*.xdc'");
my $tdcn = cmd("grep TOOL_DERIVED_CLK_NAMES $tmpdir/*.xdc");

my $name_to_entries = {};
my $obj_to_clkids_names = {};
while ($tdcn =~ /set_property TOOL_DERIVED_CLK_NAMES {(.*)} \[(.*)\]/g) {
  my $attr_str = $1;
  my $obj = $2;
  # dups within the current obj (cell/design) that are completely identical
  # (i.e. identical including the name)
  my %local_exact_dups = ();
  # collect mappings from clkid (i.e. everything but the reserved name) to
  # the reserved name. For some unknown reason, some designs have multiple
  # clkids within the same obj that map to different names.
  my $local_clkids = {};
  # current_design or get_cells ...
  $obj =~ s/get_cells {*//;
  $obj =~ s/}$//;
  print "OBJ: $obj\n";
  my @entries = split('::', $attr_str);
  foreach my $entry (@entries) {
    my @pieces = split(':', $entry);
    my $name = $pieces[5];
    if (!exists $local_exact_dups{$entry}) {
      print "  $entry\n";
      $local_exact_dups{$entry} = 1;
      my $entry_obj = "$entry ($obj)";
      $name_to_entries->{$name} = [] if (!exists $name_to_entries->{$name});
      my $arr = $name_to_entries->{$name};
      push @$arr, $entry_obj;

      my $clkid = join(':', @pieces[0 .. 4]);
      $local_clkids->{$clkid} = [] if (!exists $local_clkids->{$clkid});
      my $names = $local_clkids->{$clkid};
      push @$names, $name;
    }
  }
  $obj_to_clkids_names->{$obj} = $local_clkids;
}

print "-------------------------------------------------------------------\n";
print "DUPLICATE_REPORT\n";
print "-------------------------------------------------------------------\n";
my $num_dups = 0;
foreach my $name2 (sort keys %$name_to_entries) {
  my @objs = ();
  my $arr2 = $name_to_entries->{$name2};
  if (scalar @$arr2 > 1) {
    ++$num_dups;
    print "NAME: $name2\n";
    foreach my $entry_obj2 (@$arr2) {
      if ($entry_obj2 =~ /([^ ]*) \((.*)\)/) {
        my $entry = $1;
        my $obj2 = $2;
        print "   $entry\n";
        push @objs, $obj2;
      }
    }
    foreach my $obj3 (@objs) {
      print "   $obj3\n";
    }
  }
}

for my $obj4 (sort keys %$obj_to_clkids_names) {
  my $printed_obj = 0;
  my $clkids = $obj_to_clkids_names->{$obj4};
  for my $clkid2 (sort keys %$clkids) {
    my $names2 = $clkids->{$clkid2};
    if (scalar @$names2 > 1) {
      ++$num_dups;
      if ($printed_obj == 0) {
        print "OBJ: $obj4\n";
        $printed_obj = 1;
      }
      print "   $clkid2\n";
      for my $name3 (@$names2) {
        print "      $name3\n";
      }
    }
  }
}

cmd("ls $tmpdir");
cmd("rm -rf $tmpdir");

exit $num_dups;

sub cmd
{
  my ($cmd) = @_;
  print "CMD: $cmd\n" if $verbose;
  my $output = `$cmd`;
  chomp $output;
  print "RET: $output\n" if $verbose && length($output);
  return $output;
}
