# -*- perl -*-
#	readline.t - Test script for Term::ReadLine:GNU
#
#	$Id: readline.t,v 1.6 1997-01-19 15:13:27 hayashi Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/readline.t'

BEGIN {print "1..10\n";}
END {print "not ok 1\n" unless $loaded;}

$^W = 1;			# perl -w
use strict;
use vars qw($loaded);
use Term::ReadLine;
use Term::ReadLine::Gnu qw(:all);

$loaded = 1;
print "ok 1\n";

########################################################################
# test new method

my $term = new Term::ReadLine 'ReadLineTest';
print defined $term ? "ok 2\n" : "not ok 2\n";

########################################################################
# test ReadLine method

my $OUT = $term->OUT || \*STDOUT;

if ($term->ReadLine eq 'Term::ReadLine::Gnu') {
    print "ok 3\n";
} else {
    print "not ok 3\n";
    print $OUT ("Package name should be \`Term::ReadLine::Gnu\', but it is \`",
		$term->ReadLine, "\'\n");
}

########################################################################
# test Features method

my %features = %{ $term->Features };
if (%features) {
    my @f = %features;
#    print $OUT "Features present: @f\n";
    print "ok 4\n";
} else {
    print $OUT "No additional features present.\n";
    print "not ok 4\n";
}

# goto short_cut;
# goto end_of_test;

########################################################################
# test history expansion

print $OUT "GNU Readline Library version: $rl_library_version\n";

rl_bind_key(ord "\ct", 'operate-and-get-next');
rl_bind_key(ord "\ct", 'operate-and-get-next', 'emacs-ctlx');
rl_generic_bind(ISMACR, "\cx\co", "\c[insert from beginning of line]");

my ($fn, $type);
($fn, $type) = rl_function_of_keyseq("\co");
print "C-o: $fn,$type\n";
($fn, $type) = rl_function_of_keyseq("\ct");
print "C-t: $fn,$type\n";
($fn, $type) = rl_function_of_keyseq("\cx");
print "C-x: $fn,$type\n";
($fn, $type) = rl_function_of_keyseq("\cx\ct");
print "C-xC-t: $fn,$type\n";
($fn, $type) = rl_function_of_keyseq("\cx\co");
print "C-xC-o: $fn,$type\n";
my @keyseqs;
@keyseqs = rl_invoking_keyseqs('operate-and-get-next');
print "operate-and-get-next is bound to :", join(',',@keyseqs), "\n";
@keyseqs = rl_invoking_keyseqs('operate-and-get-next', 'emacs-ctlx');
print "operate-and-get-next is bound to \C-x :", join(',',@keyseqs), "\n";
#@keyseqs = rl_invoking_keyseqs('emacs-ctlx', '', &ISKMAP);
#print "emacs-ctlx is bound to :", join(',',@keyseqs), "\n";
#rl_parse_and_bind('"\C-o\C-t": debug');
#rl_generic_bind(0, "\\C-o\\C-o", 'debug');

print $OUT "\n# history expansion test\n";
print $OUT "# quit by EOF (\\C-d)\n";
$term->MinLine(1);
$term->StifleHistory(5);
$term->{DoExpand} = 1;
my ($nline, $line);
for ($nline = 0;
     defined($line = $term->readline("$nline>"));
     $nline++) {
    print $OUT "<<$line>>\n";
}
print $OUT "\n";
print "ok 5\n";

$term->UnbindKey("\co");

# goto end_of_test;

########################################################################
# test custom completion function

$term->readline("filename completion (default)>", "this is default string");

$rl_completion_entry_function = \&username_completion_function;
$term->readline("username completion>");

@{$term->{CompletionWordList}} =
    qw(list of words which you want to use for completion);
$rl_completion_entry_function = \&list_completion_function;
$term->readline("custom completion>");

$rl_completion_entry_function = \&filename_completion_function;
$term->readline("filename completion>");

sub sample_completion {
    my ($text, $line, $start, $end) = @_;
#    print $OUT "\n[$text:$line:$start:$end]\n";
    # If first word then username completion, else filename completion
    if (substr($line, 0, $start) =~ /^\s*$/) {
	return completion_matches($text, \&username_completion_function);
    } else {
	return ();
    }
}

$rl_attempted_completion_function = \&sample_completion;
$term->readline("username filename completion>");
$rl_attempted_completion_function = undef;

print "ok 6\n";
########################################################################
# test ParseAndBind()

$rl_inhibit_completion = 1;
$term->readline('disable completion>');
$rl_inhibit_completion = 0;
$rl_completion_append_character = ':';
$term->readline('enable completion>');
$rl_completion_append_character = ' ';

print "ok 7\n";
########################################################################
# test ParseAndBind()

$term->ParseAndBind('"\C-i": self-insert');
$term->readline('bind "\C-i" to self-insert>');

short_cut:

$term->AddDefun('reverse-line', \&reverse_line, "\co");
$term->readline('bind "\C-o" to reverse-line>');

$term->UnbindKey("\co");
$term->readline('unbind "\C-o">');

sub reverse_line {
    my($count, $key) = @_;
    my $line = $rl_line_buffer;
    #rl_modifying;
    $rl_line_buffer = reverse $line;
}

print "ok 8\n";
########################################################################
# test WriteHistory(), ReadHistory()

my @list_write = $term->GetHistory();
$term->WriteHistory(".history_test") || warn "error at write_history: $!\n";
$term->SetHistory();
$term->ReadHistory(".history_test") || warn "error at read_history: $!\n";
my @list_read = $term->GetHistory();
print equal_list(\@list_write, \@list_read) ? "ok 9\n" : "not ok 9\n";

########################################################################
# test SetHistory(), GetHistory()

my @list_set = qw(one two three);
$term->SetHistory(@list_set);
my @list_get = $term->GetHistory();
print equal_list(\@list_set, \@list_get) ? "ok 10\n" : "not ok 10\n";

sub equal_list {
    ($a, $b) = @_;
    my @a = @$a;
    my @b = @$b;
    return undef if $#a ne $#b;
    for (0..$#a) {
	return undef if $a[$_] ne $b[$_];
    }
    return 1;
}

end_of_test:
exit 0;
