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



#Versión 1.1 - Elimina linea/s o columna/s que quieras de uno o varios archivos CSV.

# Para ejecutar este programa hay que instalar las librerías: File::Slurp, LWP::Simple, Text::CSV
# Script que elimina o una fila o una columna de un archivo CSV

use File::Path qw(mkpath);
use Text::CSV;
use v5.014;
use strict;

my @inFiles;
my $line;
my $numLine;

    #Se guardan los argumentos que empiezan por csv en un array
    if(scalar(@ARGV) > 2){
        while ($ARGV[0] =~ /([\w\d]*\.[cC][sS][vV]$)/){
            push @inFiles, shift @ARGV;
        }
        if(scalar(@ARGV) >= 2){
            $line = shift @ARGV;

        }else{
            if(scalar(@ARGV)!=0){
                print "ERROR: no ha introducido los parámetros correctos\n";
                error();
                exit(0);
            }
        }
        if(scalar(@inFiles) == 0){
            print "ERROR: No ha introducido ningún argumento de tipo archivo.csv\n";
            error();
            exit(0);
        }
    }else{
        print "\n$0\nElimina la línea ó columna de los archivos .csv que se indiquen \n";
        print "FORMATO: " . $0 . " archivo.csv... <fil|col> numberLine... \n\n";
        error();
        exit(0);
    }
    
    foreach my $in (@inFiles){
        # Creamos instancia de CSV
        my $csv = Text::CSV->new ( { binary => 1, 
            quote_char          => '"',
            escape_char         => '"',
            always_quote        => 0,
            allow_loose_quotes => 1,
            eol => $/ } )  # should set binary attribute.
            or die "Cannot use CSV: ".Text::CSV->error_diag ();
        
        #Creamos el manejador de entrada
        open my $inHandler, "<:encoding(utf8)", "$in" or die "$in: $!";
        #Creamos una carpeta para el archivo modificado.
        mkpath("modificado");
        #Creamos el archivo y lo guardamos dentro de la carpeta
        open my $outHandler, ">:encoding(iso-8859-1)", "modificado/$in" or die "modificado/$in";
        #my @rows;
        if ( "col" eq $line ){
            #Ordenamos los números de líneas de mayor a menor.
            my @sortedNumLines = sort {$a <= $b}@ARGV;
            while ( my $row = $csv->getline( $inHandler ) ) {
                for( my $i=0; $i < scalar(@sortedNumLines);$i++){
                    #Se le resta uno porque empiza porque la primera columna empieza en 0
                    splice($row,$sortedNumLines[$i]-1,1);
                }
                $csv->print ($outHandler,$row);
            }
        }else{
            #Ordenamos los números de líneas de menor a mayor.
            my @sortedNumLines = sort {$a >= $b}@ARGV;
            if( "fil" eq $line){
                $numLine = int(shift @ARGV);
                my $cont=0;
                while (my $row = $csv->getline( $inHandler )){
                    #Se le resta 1 al número de linea porque el contador de línea empieza en 0
                    if($cont != ($numLine -1)){
                        $csv->print ($outHandler,$row);
                    }else{
                        if(scalar(@ARGV) >0){
                            $numLine = int(shift @ARGV);
                        }
                    }
                    #Sumamos uno en el contador de líneas.
                    $cont++;    
                }
            }else{
                say "ERROR: $line es un argumento inválido";
                say "SUGERENCIA: Escriba fil ó col en lugar de $line";
                say "ó";
                error();
                exit(-1); 
            }
        }
        close($inHandler);
        close($outHandler);
    }

sub error{
    say "Ejecuta: perl deleteLine.pl archivo.csv... <fil|col> numberLine...";
    say "|--Ejemplo: perl deleteLine.pl archivo.csv fil 1 4 5";
    say "|--Ejecución: Borrará las filas 1, 4 y 5 de archivo.csv";
    return -1;
}
