#!/usr/bin/env perl
#use strict;
use warnings;
package NiceBot;
use base "Bot::BasicBot";
use Bone::Easy;
use IMDB::Film;
use IMDB::Persons;
use List::Util qw(shuffle);
use Acme::Magic8Ball qw(ask);
use FindBin qw($Bin);

# Numberwang Variables.
my $numberwang_flag = 0;
my $numberwang_chan;
my %numberwang_scores; 

# Array to hold GLADOS quotes.
my @glados_quotes;

# Load in the glados quotes file.
$DATA = "$Bin/glados.txt";
open(DATA) or die("Could not open GLADOS Quotes file.");
foreach $line (<DATA>) {
  chomp($line); # remove the newline from $line.
  push(@glados_quotes, $line);
}

# Init NiceBot!
NiceBot->new(
	     server => "stitch.chatspike.net",
	     port   => "6667",
	     channels => ["#pub", "#nicebot"],
	     nick      => "NiceBot",
	     alt_nicks => ["VeryNiceBot"],
	     username  => "nicebot",
	     name      => "Mrs Nice Bot",
	     charset => "utf-8", # charset the bot assumes the channel is using
	    )->run();

#------------------------------------------------------------------------
# Start of callbacks for IRC actions
#------------------------------------------------------------------------

# Callback when someone says something. Most of the functionality is in here.
sub said {

  my ($self, $args) = @_;

  use Data::Dumper;
  print Dumper($args);

  # Mostly here to piss off calamari
  eval {

    # Welcome People
    if ($args->{body} =~ /(hello|hi|hey)/i) {
    }

    # Numberwang Start command.
    if ($args->{body} =~ /numberwang: start/i) {
      $numberwang_flag = $args->{channel};
      $numberwang_flag = 1;
      $self->say(body => "Let's play Numberwang!", channel => $args->{channel});
    }

    # Numberwang Stop command.
    if ($args->{body} =~ /numberwang: stop/i) {

      my $highest_score = 0;
      my $highest_score_name;

      foreach $foo (keys %numberwang_scores) {
	if ($numberwang_scores{$foo} > $highest_score) {
	  $highest_score_name = "$foo";
	}
      }

      $self->say(body => "Thanks for playing! Tonight's winner was: $highest_score_name!", channel => $args->{channel});
      $numberwang_flag = 0;
      %numberwang_scores = {};
    }

    # Numberwang Gameplay Functionality.
    if (($args->{body} =~ /\d+/) and ($numberwang_flag == 1)) {

      my $random_number = int(rand(8));

      print "NiceBot has picked: $random_number as her random number.";

      if ($random_number == 1) {
	$self->say(body => "$args->{who}, That's Numberwang! ", channel => $args->{channel});
	$numberwang_scores{$args->{who}} = $numberwang_scores{$args->{who}} + 1;
      }

    }

    # GLADOS Cake
    # if ($args->{body} =~ /cake/i) {
    #   $self->say(body => "The cake is a lie.", channel => $args->{channel});
    # }

    # GLADOS Quotes
    if ($args->{body} =~ /glados:/i) {
      @quotes = shuffle(@glados_quotes);
      $self->say(body => "$quotes[0]", channel => $args->{channel});
    }

    # Magic Eightball
    if ($args->{body} =~ /eightball:\s*(.*)/i) {
        if ($args->{body}  =~ /pizza/i ) {
            $self->say(body => "$args->{who}, " . "Pizza?! YES!", channel => $args->{channel});
        }
        else {
            $self->say(body => "$args->{who}, " . ask($1), channel => $args->{channel});
        }
    }

    # IMDB Movie titles (Eval'd to prevent crash)
    if ($args->{body} =~ /imdb:\s*(.*)/i) {

      eval {
	my $imdbObj = new IMDB::Film(crit => $1);
	my $plot_keywords = $imdbObj->plot_keywords();
	my $keywords;
	my $limit = 5;
	my $count = 0;

	my @rnd = shuffle(@$plot_keywords);

	for my $keyword (@rnd) {
	  $count++;
	  $keywords .= "$keyword, ";
	  last if $count >= $limit;
	}

	$self->say(body => $imdbObj->title() . " - " . $imdbObj->year() . " - " . $imdbObj->rating() . "/10 - $keywords", channel => $args->{channel});
      };

      if ($@) {
	$self->say(body => "Uhoh! That IMDB query caused something to go wrong :( Why not try something else?", channel => $args->{channel});
      }

    }

    # IMDB People (Eval'd to prevent crash)
    if ($args->{body} =~ /imdbname:\s*(.*)/i) {

      eval {
	my $imdbObj = new IMDB::Persons(crit => $1);
	my $plot_keywords = $imdbObj->plot_keywords();
	my $keywords;
	my $limit = 5;
	my $count = 0;

	my @rnd = shuffle(@$plot_keywords);

	for my $keyword (@rnd) {
	  $count++;
	  $keywords .= "$keyword, ";
	  last if $count >= $limit;
	}

	$self->say(body => $imdbObj->name() . " - " . $imdbObj->date_of_birth() . " - $keywords", channel => $args->{channel});
      };

      if ($@) {
	$self->say(body => "Uhoh! That IMDB query caused something to go wrong :( Why not try something else?", channel => $args->{channel});
      }

    }

    # IMDB Movie Recomendations (Eval'd to prevent crash)
    if ($args->{body} =~ /imdblike:\s*(.*)/i) {

      eval {
	my $imdbObj = new IMDB::Film(crit => $1);

	my $recs = $imdbObj->recommendation_movies();

	print Dumper($recs);

	my $rec_string;
	my $limit = 5;
	my $count = 0;

	for my $film (values (%$recs)) {
	  $count++;
	  $rec_string .= "$film, ";
	  last if $count >= $limit;
	}

	$self->say(body => "You might also like: $rec_string", channel => $args->{channel});
      };

      if ($@) {
	$self->say(body => "Uhoh! That IMDB query caused something to go wrong :( Why not try something else?", channel => $args->{channel});
      }

    }

    # Bone...
    if ($args->{body} =~ /bone:/i) {
      $self->say(body => pickup(), channel => $args->{channel});
    }
  };

  # Someone managed to break NiceBot. :(
  if ($@) {
    $self->say(body => "Oh my. You broke me. Someone call GeneticGenesis!", channel => $args->{channel});
  }
}

sub userquit {

  my ($self, $args) = @_;

  use Data::Dumper;
  print Dumper($args);

  #$self->say(body => "Isn't $args->{who} so much fun!", channel => $args->{channel});
  return;
}

sub chanpart {

  my ($self, $args) = @_;

  use Data::Dumper;
  print Dumper($args);

  #$self->say(body => "Isn't $args->{who} so much fun!", channel => $args->{channel});

  return;

}


sub chanjoin {

  my ($self, $args) = @_;

  use Data::Dumper;
  print Dumper($args);

  if ($args->{who} =~ /GeneticGenesis/) {
    #	$self->say(body => "I love you, $args->{who}", channel => $args->{channel});
    return;
  }

}
