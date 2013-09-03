#!/usr/bin/perl
use WWW::TheMovieDB;
use Web::Scraper;
use URI;
use LWP::UserAgent qw();
use RTPG;
use Data::Dumper;
$rt = new RTPG(url=>'10.20.10.34:5000');
my $api = new WWW::TheMovieDB({
	'key'           =>      '57983e31fb435df4df77afb854740ea9',
        'language'      =>      'en',
        'version'       =>      '3',
        'uri'           =>      'http://api.themoviedb.org'
});
$ua = LWP::UserAgent->new;
$search=$ARGV[0];
$quality="+xvid" unless $ARGV[1];
die "Error: No Movie Entered!" unless $ARGV[0];
$s= $api->Search::movie({
	'query' => $search
});
my @v = split('}', $s);

foreach(@v){
$_=~s/].*//g;
$_=~s/","poster_path".*//g;
$_=~s/.*"id":\d{1,9},"original_title":"//g;
$_=~s/"/  /;
$_=~s/,"release_date":"//g;
push(@a, "$_");
}

%hash = ();
$count=1;
foreach(@a){
if($_){
print "$count) $_\n";
$hash{ $count } = $_;
$count++;
}
}
print "========================== Pick the film from the list ==========================\n";
print "ID: ";
$id = <STDIN>;
$id=~s/\n//g;
$name=$hash{"$id"};
$year=$name;
$year=~m/(\d{1,4}-\d{1,2}-\d{1,2})/;
$year=$1;
$year=~m/(\d{1,4})/;
$year=$1;
$name=~s/  \d{1,4}-\d{1,2}-\d{1,2}//;
$name=~s/: .*/ /g;
$name=~s/\.//g;
$searchable="$name $year";
$searchable=~s/ /+/g;
my $links = scraper {
	 process ".results", "info[]" => scraper {
        	  process 'dl>dt>a', 'link[]' => '@href';
		  process "dl>dt>a", 'text[]' => 'TEXT';
	};
};


my $search = $links->scrape( URI->new("http://torrentz.eu/search?f=movies$quality+seed+>+5+$searchable") );

#create hashes
%hash_names=();
%hash_links=();
$count=1;
for my $result (@{$search->{info}}) {
for my $link (@{$result->{link}}){
	$hash_links{ $count } = $link;
	$count++;
	}
$count=1; # reset count for next hash 
for my $text (@{$result->{text}}){
	$hash_names{ $count} = $text;
	$count++;	
	}
}

unless(%hash_names && %hash_links){
print "Standard quality lookup failed, moving on to HD!\n";
my $search = $links->scrape( URI->new("http://torrentz.eu/search?f=movies+seed+>+5+$searchable") );
%hash_names=();
%hash_links=();
$count=1;
for my $result (@{$search->{info}}) {
for my $link (@{$result->{link}}){
        $hash_links{ $count } = $link;
        $count++;
        }
$count=1; # reset count for next hash 
for my $text (@{$result->{text}}){
        $hash_names{ $count} = $text;
        $count++;
        }
}
}

%rhash_names = reverse %hash_names;

### need to do some sort of sanity checks on the %hash_names, find the best looking ones and then use the key it is assigned to lookup %hash_links for the links to use 
$count=0;
foreach my $n (values %hash_names) {
	if ($n=~m/^$name/){
		if ($n!~m/^$name \d /){
			$key = $rhash_names{$n};
			if($count<=10){
				push(@links, $hash_links{$key});
				$count++;
			}
		}
	}
}

$ct=0;
until($ct==10){
my $t = scraper {
                  process '.download>dl>dt>a', 'links[]' => '@href';
};
$res = $ua->head($links[$ct]);
if($res->is_success){
my $search_torrent = $t->scrape( URI->new("$links[$ct]") );
@t=();
for my $torrent_link (@{$search_torrent->{links}}) {
push(@t, $torrent_link);
}
		foreach(@t){
			if ($_ =~ m/torrenthound.com|katmirror.com/) {
				push(@torrent_site_links, $_);
			}
		}
	}
$ct++;
}
$total_links=@torrent_site_links;
$total_links=1 unless $total_links;
$complete=0;
until($complete==1){

	$torrent;
	if($torrent_site_links[$ct2]=~m/katmirror.com/){
	$torrent=katmirror($torrent_site_links[$ct2]);	
	}elsif($torrent_site_links[$ct2]=~m/torrenthound.com/){
	$torrent=torrenthound($torrent_site_links[$ct2]);
	}if($torrent){
		$complete=add_and_check($torrent);	
	}
	if($complete==0){
		$ct2++;
	}
	if($ct2 == $total_links){
		print "Failed, Coudn't find a torrent file, will have to be a manual lookup\n";
		$complete=1;
	}
}




##Subs

##katmirror.com
sub katmirror{
my $kat=shift;
$res = $ua->head($kat);
if($res->is_success){
my $file_type = scraper {
                 process '.torrentFileList ', 'files[]' => 'TEXT';
       };
       my $type = $file_type->scrape( URI->new("$kat") );
		for my $k (@{$type->{files}}){
		$ok=0;
		if($k=~m/(.avi|.mkv|.mp4)/){ 
			if($k!~m/(Disc 1|Disk 1|CD01.avi|CD1.avi|CD2.avi|CD02.avi|CD01.mp4|CD02.mp4|CD1|CD2|cd1|cd2|.r01|.rar)/){
				$ok=1;
			}
		}
	}
if($ok==1){
my $s = scraper {
	process '.siteButton.giantButton', 'url' => '@href';
        };
my $u = $s->scrape( URI->new("$kat") );
$url= $u->{url};
return $url;
	}
}
}



##torrenthound.com
sub torrenthound{
my $t_hound=shift;
$res = $ua->head($t_hound);
if($res->is_success){
	my $file_type = scraper {
                 process 'li.leaf', 'files[]' => 'TEXT';
       };
       my $type = $file_type->scrape( URI->new("$t_hound") );
		for my $t (@{$type->{files}}){
		$ok=0;
		if($t=~m/(.avi|.mkv|.mp4)/){
			if($t!~m/(Disc 1|Disk 1|CD01.avi|CD1.avi|CD2.avi|CD02.avi|CD01.mp4|CD02.mp4|CD1|CD2|cd1|cd2|.r01|.rar)/){
				$ok=1;
			}
		}
	}
if($ok==1){
my $s = scraper {
        process '.button>a[rel="nofollow"]', 'url' => '@href';
        };
	my $u = $s->scrape( URI->new("$t_hound") );
	$url= $u->{url};
		return $url;
		}
	}
}

sub add_and_check{
my $t=shift;
$rt->add("$t");
sleep(4);

$tlist=$rt->torrents_list('stopped');
for (@$tlist){
        my $hash=$_->{hash};
	my $name=$_->{name};
	my $t_files=$rt->file_list($hash);
		for (@$t_files){
		push (@files, $_->{path});
		}
		foreach(@files){
			$file=$_;
				if($file=~m/.r00|.r01|.rar|CD01|CD02|cd01|cd02|CD1|CD2|cd1|cd2|.zip/){
					print "Matches the fails\n";
				$kk=0
			}
		}
				if($kk ne 0){
        			$rt->start($hash);
				print "Starting $name\n";
				$kk=1;
				}else{
				print "Delting $name\n";
				$rt->delete($hash);
				}
	}
	if($kk==1){
	return 1;
	}else{
	return 0;
	}
}
