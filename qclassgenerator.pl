#!/usr/bin/perl

## Copyright Arnaud Dupuis <a [dot] dupuis [at] infinityperl [dot] org>

use warnings;
use strict;
use Data::Dumper;

sub loadConfig {
	my $cfg = shift;
	open(my $fh,'<',shift(@_)) or die $!;
	while(<$fh>){
		chomp;
		next if(/^[#\/!*]+/);
# 		print "Processing: $_\n";
# 		my ($key,$value)=split(/=/,$_);
		my ($key,$value)= $_ =~ /^([^=]+)\s*=\s*(.+)$/;
		$cfg->{$key} = $value unless(defined($cfg->{$key}));
	}
	close($fh);
}
sub loadFile {
	my $file = shift;
	my $content = "";
	open(my $fh,'<',$file) or die "$file: $!\n";
	while(<$fh>){
		$content .= $_;
	}
	close($fh);
	return $content;
}
sub writeFile {
	my $file = shift;
	my $data = shift;
	open(my $fh,'>',$file) or die "$file: $!\n";
	print $fh $data;
	close($fh);
}
my $config={templates_basedir=>'./templates'};
$config->{templates_basedir}=$ENV{QCG_TEMPLATE_PATH} if(defined($ENV{QCG_TEMPLATE_PATH}) && $ENV{QCG_TEMPLATE_PATH});
print "templates base directory is: $config->{templates_basedir}\n";
my $members = {};
my $extra = {};
my $code_gen = {
	constructor_inline => "",
	constructor_body => "",
	includes => "",
	variables_declarations => "",
	getters_code => "",
	getters_headers => "",
	setters_code => "",
	setters_headers => "",
	signals_headers => "",
	property => "",
	extra_includes => "",
	copy_operator => ""
};
loadConfig($config,$ARGV[0]);
die "[fatal] Class name must not be null.\n" unless(defined($config->{class}));
$config->{template} = 'Qt4' unless(defined($config->{template}) && $config->{template});
die "[fatal] Template $config->{template} does not provide a $config->{template}/template.ini file.\n" unless( -e "$config->{templates_basedir}/".$config->{template}."/template.ini" );
die "[fatal] Template $config->{template} does not provide a $config->{template}/template.cpp file.\n" unless( -e "$config->{templates_basedir}/".$config->{template}."/template.cpp" );
die "[fatal] Template $config->{template} does not provide a $config->{template}/template.h file.\n" unless( -e "$config->{templates_basedir}/".$config->{template}."/template.h" );
loadConfig($config,"$config->{templates_basedir}/".$config->{template}."/template.ini");
mkdir $config->{output} unless(-e $config->{output});
$code_gen->{class_file} = lc($config->{class});
$code_gen->{class_name} = ucfirst($config->{class});
$code_gen->{mipt} = uc($config->{class})."_H";
if( defined($config->{members}) ){
	foreach my $member (split(/;/,$config->{members})){
		if($member =~ /^([^{]+)\{([^}]+)\}$/){
			print "Processing key=$1 & value=$2\n";
			$members->{$1} = $2;
		}
		elsif($member =~ /^([^{]+)\{([^}]+)\}\{([^}]+)\}$/){
			print "Processing key=$1 & value=$2 & extra=$3\n";
			$members->{$1} = $2;
			$extra->{$3}{$1} = $2;
		}
		elsif($member =~ /^([^{]+)\{([^}]+)\}\{([^}]+)\}\{([^}]+)\}$/){
			print "Processing key=$1 & value=$2 & extra=$3 extra2=$4\n";
			$members->{$1} = $2;
			$extra->{$3}{$1} = $2;
			$extra->{classinfo}{$1} = $4;
		}
	}
	print Data::Dumper::Dumper($extra),"\n";
}
else {
	die "[fatal] Members must not be null.\n";
}
print "starting generation of class: $code_gen->{class_name}\n";
foreach my $mn (sort(keys %{$members})){
	print "\tprocessing member: $mn\n";
	if($members->{$mn} =~ /^$config->{prefix}/){
		$code_gen->{constructor_inline} .= ",m_$mn()";
		if($members->{$mn} =~ /</){
			my($type,$list_type) = split(/</,$members->{$mn});
			chop $list_type;
			unless(defined($code_gen->{included}->{$type})){
				$code_gen->{includes} .= "#include <$type>\n" ;
				$code_gen->{included}->{$type}=1;
			}
			if($list_type =~ /,/){
				my ($type1,$type2) = split(/,/,$list_type);
				unless(defined($code_gen->{included}->{$type1})){
					$code_gen->{includes} .= "#include <$type1>\n" ;
					$code_gen->{included}->{$type1}=1;
				}
				unless(defined($code_gen->{included}->{$type2})){
					$code_gen->{includes} .= "#include <$type2>\n" ;
					$code_gen->{included}->{$type2}=1;
				}
			}
			else {
				unless(defined($code_gen->{included}->{$list_type})){
					$code_gen->{includes} .= "#include <$list_type>\n" ;
					$code_gen->{included}->{$list_type}=1;
				}
			}
		}
		else{
			unless(defined($code_gen->{included}->{$members->{$mn}})){
				$code_gen->{includes} .= "#include <$members->{$mn}>\n";
				$code_gen->{included}->{$members->{$mn}}=1;
			}
		}
	}
	else {
		if( defined($config->{'type:'.$members->{$mn}}) ){
			my $init_code = $config->{'type:'.$members->{$mn}};
			$init_code =~ s/\$member/m_$mn/;
			$code_gen->{constructor_body} .= "\tm_$mn = ".$init_code.";\n";
		}
	}
	$code_gen->{variables_declarations} .= "\t$members->{$mn} m_$mn;\n";
	if( defined($config->{"doc:get:$mn"}) && $config->{"doc:get:$mn"} ne "" ){
		$code_gen->{getters_headers} .= "\n\t/*!\n\t".$config->{"doc:get:$mn"}."\n\t\\return m_$mn as a $members->{$mn}\n\t*/\n\t$members->{$mn} $mn() ;\n\n";
	}
	else{
		$code_gen->{getters_headers} .= "\n\t/*!\n\tGet <complete description here>.\n\t\\return m_$mn as a $members->{$mn}\n\t*/\n\t$members->{$mn} $mn() ;\n\n";
	}
	if(defined($config->{fk_prefix}) && $config->{fk_prefix} && $members->{$mn} =~ /^$config->{fk_prefix}/){
		$code_gen->{setters_code} .= "void $code_gen->{class_name}::set".ucfirst($mn)."(const $members->{$mn} & p_$mn) {\n\tm_$mn=p_$mn;\n\tsetForeignKey(\"$mn\",m_$mn);\n\temit(".$mn."Changed(m_$mn));\n}\n\n";
		$code_gen->{getters_code} .= "$members->{$mn} $code_gen->{class_name}::$mn() {\n\treturn qobject_cast<$members->{$mn}*>(foreignKey(\"$mn\"));\n}\n\n";
	}
	else{
		$code_gen->{setters_code} .= "void $code_gen->{class_name}::set".ucfirst($mn)."(const $members->{$mn} & p_$mn) {\n\tm_$mn=p_$mn;\n\temit(".$mn."Changed(m_$mn));\n}\n\n";
		$code_gen->{getters_code} .= "$members->{$mn} $code_gen->{class_name}::$mn() {\n\treturn m_$mn;\n}\n\n";
	}
	if( defined($config->{"doc:set:$mn"}) && $config->{"doc:set:$mn"} ne "" ){
		$code_gen->{setters_headers} .= "\n\t/*!\n\t".$config->{"doc:set:$mn"}."\n\t*/\n\tvoid set".ucfirst($mn)."(const $members->{$mn} & p_$mn) ;\n\n";
	}
	else{
		$code_gen->{setters_headers} .= "\n\t/*!\n\tSet <complete description here>.\n\t*/\n\tvoid set".ucfirst($mn)."(const $members->{$mn} & p_$mn) ;\n\n";
	}
	$code_gen->{signals_headers} .= "\tvoid ".$mn."Changed(const $members->{$mn} & p_$mn);\n";
	$code_gen->{copy_operator} .= "\tthis->m_$mn = p_obj.m_$mn;\n";
}
foreach my $pn (sort(keys %{$extra->{property}})){
	$code_gen->{properties} .= "\tQ_PROPERTY($extra->{property}->{$pn} $pn READ $pn WRITE set".ucfirst($pn).")\n";
}
foreach my $cin (sort(keys %{$extra->{classinfo}})){
	$code_gen->{properties} .= "\tQ_CLASSINFO(\"$cin\", \"$extra->{classinfo}->{$cin}\")\n";
}
print "\twatching for extra includes\n";
if( defined($config->{extra_includes}) && $config->{extra_includes} ){
	print "\t\textra includes found\n";
	foreach my $ei (split(/;/,$config->{extra_includes})){
		print "\t\t\tincluding $ei\n";
		$code_gen->{extra_includes} .= "#include \"$ei\"\n";
	}
}
print "class generation done.\n";
my $cpp_file = loadFile("$config->{templates_basedir}/".$config->{template}."/template.cpp");
my $h_file = loadFile("$config->{templates_basedir}/".$config->{template}."/template.h");
$cpp_file=~ s/\/\*__CLASS_FILE__\*\//$code_gen->{class_file}/g;
$cpp_file=~ s/\/\*__CLASS_NAME__\*\//$code_gen->{class_name}/g;
$cpp_file=~ s/\/\*__INLINE_INIT__\*\//$code_gen->{constructor_inline}/g;
$cpp_file=~ s/\/\*__BODY_INIT__\*\//$code_gen->{constructor_body}/g;
$cpp_file=~ s/\/\*__SETTERS__\*\//$code_gen->{setters_code}/g;
$cpp_file=~ s/\/\*__GETTERS__\*\//$code_gen->{getters_code}/g;
$cpp_file=~ s/\/\*__COPY_OPERATOR_CODE__\*\//$code_gen->{copy_operator}/g;

$h_file=~ s/\/\*__GETTERS_H__\*\//$code_gen->{getters_headers}/g;
$h_file=~ s/\/\*__SETTERS_H__\*\//$code_gen->{setters_headers}/g;
$h_file=~ s/\/\*__MIPT__\*\//$code_gen->{mipt}/g;
$h_file=~ s/\/\*__CLASS_NAME__\*\//$code_gen->{class_name}/g;
$h_file=~ s/\/\*__INCLUDES__\*\//$code_gen->{includes}/g;
$h_file=~ s/\/\*__MEMBER_VARIABLES__\*\//$code_gen->{variables_declarations}/g;
$h_file=~ s/\/\*__SIGNALS__\*\//$code_gen->{signals_headers}/g;
$h_file=~ s/\/\*__PROPERTIES__\*\//$code_gen->{properties}/g;
$h_file=~ s/\/\*__EXTRA_INCLUDES__\*\//$code_gen->{extra_includes}/g;

print "saving C++ in: $config->{output}/$code_gen->{class_file}.cpp\n";
writeFile($config->{output}."/$code_gen->{class_file}.cpp",$cpp_file);
print "saving header in: $config->{output}/$code_gen->{class_file}.h\n";
writeFile($config->{output}."/$code_gen->{class_file}.h",$h_file);
