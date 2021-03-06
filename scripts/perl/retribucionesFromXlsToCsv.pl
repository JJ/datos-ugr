#!/usr/bin/env perl

#       CopyRight 2014 Óscar Zafra (oskyar@gmail.com)
#
#       This program is free software: you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation, either version 3 of the License, or
#       (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#       You should have received a copy of the GNU General Public License
#       along with this program.  If not, see <http://www.gnu.org/licenses/>.

#Versión 1 - Descarga los archivos .xls de la página, los pasa a csv completamente.

#Para ejecutar este programa hay que instalar las librerías, JSON, File::Slurp, LWP::Simple, URI::http
#Módulo para pasar de xls a csv http://search.cpan.org/~ken/xls2csv/script/xls2csv

use File::Slurp qw(read_file);
use File::Path qw(mkpath);
use LWP::Simple;
use Web::Scraper;
use MIME::Types qw();
use Smart::Comments '###';
use Term::ANSIColor;
use Spreadsheet::ParseExcel qw(worksheet );
use Spreadsheet::ParseExcel::Workbook qw(get_name);
use v5.014;
use strict;
use warnings;
use YAML qw(LoadFile);

my $workbook;
my $parser  = Spreadsheet::ParseExcel->new();
my $mimetypes = MIME::Types->new();

my @variables = LoadFile('./retribucionesFromXlsToCsv.yml');

#Esto debe de ser un parámetro pasado al programa.
my $format = "xls";
my $type = $mimetypes->mimeTypeOf($format);

# URL para hacer scraping    
my $url_to_scrape = $variables[0]->{'urlToScrape'};

# Preparamos los datos
my $teamsdata = scraper {
    # Guardaremos el enlace de las url que tengan esta estructura
    process "a", 'urls[]' => '@href';
    # Guardaremos el texto que hay en las URL dentro de esta estructura
    process "a", 'teams[]' => 'TEXT';
};

# "Scrapeando" los datos
my $res = $teamsdata->scrape(URI->new($url_to_scrape));

#Creamos la carpeta donde se almacenarán los archivos exportados
mkpath("csv");
#Procesamos todas las URL de la página comprobando su cabecera.
for my $i (0 .. $#{$res->{'teams'}}) { ### Procesando [===|         ] % Terminado
    my @info = head($res->{urls}[$i]);  
    #Comparo MIME del archivo y si es del tipo que quiero, paso a descargar y procesar.
    if($info[0] =~ m/$type/){
        # Hash con el texto que acompaña a la URL y la URL {texto, url}
        my $name = $res->{'teams'}[$i];
        $name =~ s/(^ )|( $)//g;
        # Me descargo los archivos de los enlaces que se han guardado.
        my $code = getstore($res->{urls}[$i],"$name.$format");
        my $workbook = $parser->parse("$name.$format");
        if ( !defined $workbook ){
            print "ERROR: ".$parser->error(), " \[$name\]\n";
        }else{
             #print "\n\n$name.xls\n\n";
             xls2csv("$name", $workbook);
        }
    }
}

sub xls2csv{
    my $command = " xls2csv -x \"$_[0].$format\" -b ISO-8859-1 -c csv/\"$_[0].csv\" -a UTF-8 -f -q";
    
    ## Archivo creado: $_[0].".csv"
    print color 'bold green';
    print ("\nArchivo creado: $_[0].csv\n");
    print color 'reset';
    system($command);
    if ($?) {
        print "[ERROR] command failed: $!\n";
        print "[ERROR] No se ha podido ejecutar el comando para la entrada \"$_[0].$format\" y la salida: \"$_[0].csv\"\n";
    }
}
