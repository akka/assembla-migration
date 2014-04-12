#!/usr/bin/perl

use strict;
use warnings;

my $template = &template();
my $number = 1;

sub template() {
  open my $f, "<transform.xslt.template" or die "cannot read template: $!\n";
  local $/;
  my $t = <$f>;
  close $f;
  return $t;
}

sub write_template($) {
  my ($n) = @_;
  open my $f, ">transform.xslt" or die "cannot write transform.xslt: $!\n";
  print $f ($template =~ s'@milestone@'$n're);
}

-e 'output' and die "please move 'output' out of the way\n";
mkdir 'output' or die "cannot create directory 'output': $!\n";
mkdir 'output/issues' or die "cannot create directory 'output/issues': $!\n";
mkdir 'output/milestones' or die "cannot create directory 'output/milestones': $!\n";

while (<report-*>) {
  my $report = $_;
  print "translating $report\n";
  my ($milestone, $name) = /report-(\d+)-(.*)\.xml/ or die "cannot parse $_\n";
  write_template($milestone);
  open my $mf, ">output/milestones/$milestone.json" or die "cannot create milestone $milestone: $!\n";
  print $mf <<EOF;
{
  "number" : $milestone,
  "state" : "open",
  "title" : "$name",
  "description" : "automatically imported",
  "creator" : "rkuhn",
  "created_at" : "2014-04-10T09:00:00Z"
}
EOF
  close $mf;
  open $mf, "xsltproc transform.xslt $report|" or die "cannot run xsltproc: $!\n";
  local $/ = "---\n";
  while (<$mf>) {
    chomp;
    next unless length > 10;
    open my $issue, ">output/issues/$number.json" or die "cannot create issue $number: $!\n";
    print $issue $_;
    close $issue;
    $number++;
  }
}
