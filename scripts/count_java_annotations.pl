#!/usr/bin/env perl
# count_java_annotations.pl - Extension for cloc to count Java annotations
# Copyright (C) 2026 
#
# This script extends cloc to count different types of Java annotations
# in addition to standard line counting.
#
# Usage: ./count_java_annotations.pl [files or directories]
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

use strict;
use warnings;
use File::Find;
use File::Basename;
use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case);

my $VERSION = "1.0";

# Command line options
my @filter_annotations = ();
my $show_help = 0;
my $case_sensitive = 0;
my $table_output = 0;
my $latex_output = 0;
my $input_file = '';
my @suppress_prefixes = ();

# Hash to store annotation counts globally
my %annotation_counts = ();
my %file_annotation_counts = ();
my $total_files = 0;
my $total_annotations = 0;

sub normalize_suppress_prefix {
    my ($prefix) = @_;
    return $case_sensitive ? $prefix : lc($prefix);
}

sub count_suppress_warning_values {
    my ($text, $local_annotations_ref, $file_annotation_count_ref) = @_;

    return unless @suppress_prefixes;

    while ($text =~ /"((?:[^"\\]|\\.)*)"/g) {
        my $warning = $1;
        $warning =~ s/\\"/"/g;
        my $candidate = normalize_suppress_prefix($warning);

        foreach my $prefix (@suppress_prefixes) {
            my $normalized_prefix = normalize_suppress_prefix($prefix);
            next unless index($candidate, $normalized_prefix) == 0;

            my $annotation = '@SuppressWarnings:' . $prefix;
            $local_annotations_ref->{$annotation}++;
            $annotation_counts{$annotation}++;
            $$file_annotation_count_ref++;
            $total_annotations++;
        }
    }
}

sub count_suppress_warnings_in_line {
    my ($line, $suppress_buffer_ref, $local_annotations_ref, $file_annotation_count_ref) = @_;

    return unless @suppress_prefixes;

    if ($$suppress_buffer_ref ne '') {
        $$suppress_buffer_ref .= ' ' . $line;
        if ($line =~ /\)/) {
            count_suppress_warning_values($$suppress_buffer_ref, $local_annotations_ref, $file_annotation_count_ref);
            $$suppress_buffer_ref = '';
        }
        return;
    }

    while ($line =~ /\@SuppressWarnings\s*\((.*)/g) {
        my $args = $1;
        if ($args =~ /\)/) {
            $args =~ s/\).*//s;
            count_suppress_warning_values($args, $local_annotations_ref, $file_annotation_count_ref);
        } else {
            $$suppress_buffer_ref = $args;
        }
    }
}

sub count_annotations_in_file {
    my ($file) = @_;
    
    return unless -f $file && -r $file;
    return unless $file =~ /\.java$/i;
    
    open my $fh, '<', $file or do {
        warn "Cannot open $file: $!\n";
        return;
    };
    
    my %local_annotations = ();
    my $in_block_comment = 0;
    my $suppress_buffer = '';
    my $file_annotation_count = 0;
    my $loc = 0;  # Lines of code counter
    
    while (my $line = <$fh>) {
        # Remove trailing newline
        chomp $line;
        
        # Skip blank lines for LOC count
        if ($line =~ /^\s*$/) {
            next;
        }
        
        # Skip line comments FIRST (before block comment tracking)
        if ($line =~ /^\s*\/\//) {
            next;
        }
        
        # Remove inline // comments from the line before processing
        my $code_line = $line;
        $code_line =~ s{//.*$}{};

        my $processed_line = $code_line;
        $processed_line =~ s{//.*$}{};
        
        # Remove string literals to avoid false positives from /* or */ in strings
        # This handles both single and double quotes
        $processed_line =~ s/"(?:[^"\\]|\\.)*"/""/g;
        $processed_line =~ s/'(?:[^'\\]|\\.)*'/''/g;
        
        # Track block comments to avoid counting annotations in comments
        # Check the processed line (without // comments and strings)
        if ($processed_line =~ m{/\*} && $processed_line !~ m{\*/}) {
            $in_block_comment = 1;
        }
        if ($in_block_comment) {
            if ($processed_line =~ m{\*/}) {
                $in_block_comment = 0;
            }
            next;
        }
        
        # Remove block comments that are on a single line
        $processed_line =~ s{/\*.*?\*/}{}g;
        $code_line =~ s{/\*.*?\*/}{}g;
        
        # If after removing comments the line is empty, skip LOC count
        if ($processed_line !~ /\S/) {
            next;
        }
        
        # Count this as a line of code
        $loc++;

        count_suppress_warnings_in_line(
            $code_line,
            \$suppress_buffer,
            \%local_annotations,
            \$file_annotation_count
        );
        
        # Find annotations - they start with @ and are followed by identifier
        # Handle both simple and parameterized annotations
        # Examples: @Override, @SuppressWarnings("unchecked"), @RequestMapping("/path")
        while ($processed_line =~ /@(\w+(?:\.\w+)*)/g) {
            my $annotation = '@' . $1;
            
            # Apply filter if specified
            if (@filter_annotations) {
                my $matches = 0;
                foreach my $filter (@filter_annotations) {
                    if ($case_sensitive) {
                        $matches = 1 if $annotation eq $filter;
                    } else {
                        $matches = 1 if lc($annotation) eq lc($filter);
                    }
                    last if $matches;
                }
                next unless $matches;
            }
            
            $local_annotations{$annotation}++;
            $annotation_counts{$annotation}++;
            $file_annotation_count++;
            $total_annotations++;
        }
    }
    
    close $fh;
    
    if (%local_annotations || $loc > 0) {
        if (%local_annotations) {
            $total_files++;
        }
        $file_annotation_counts{$file} = {
            count => $file_annotation_count,
            loc => $loc,
            annotations => { %local_annotations }
        };
    }
}

sub process_file {
    return unless -f $_;  # Only process files
    my $file = $File::Find::name;
    count_annotations_in_file($file);
}

sub print_usage {
    print <<'USAGE';
Usage: count_java_annotations.pl [options] [files or directories]

Count Java annotations in .java files

Options:
  -a, --annotation <name>   Count only specified annotation(s). Can be used multiple times.
                            Examples: -a @Override -a @Test
                            Note: Include the @ symbol or not, both work.
  -s, --suppress-prefix <prefix>
                            Count @SuppressWarnings values that start with the prefix.
                            Can be used multiple times. Example: -s pico
  -f, --file <filename>     Read list of files from a file (one filename per line)
  -c, --case-sensitive      Make annotation matching case-sensitive (default: case-insensitive)
  -t, --table               Output results as CSV table format
  -l, --latex               Output results as LaTeX table format
  -h, --help                Show this help message

Examples:
  # Count all annotations in a directory
  count_java_annotations.pl src/
  
  # Count only @Test annotations
  count_java_annotations.pl -a @Test src/test/

  # Count @SuppressWarnings entries whose warning key starts with pico
  count_java_annotations.pl -s pico src/
  
  # CSV table format with specific annotations as columns
  count_java_annotations.pl -t -a @Test -a @Override -a @Deprecated src/

  # LaTeX table format
  count_java_annotations.pl -l -a @Test -a @Override -a @Deprecated src/

  # Read files from a file
  count_java_annotations.pl -f filelist.txt -a @Override
  
  # Case-sensitive matching
  count_java_annotations.pl -c -a @Override src/

USAGE
    exit 0;
}
    
sub main {
    # Parse command line options
    GetOptions(
        'annotation|a=s' => \@filter_annotations,
        'suppress-prefix|s=s' => \@suppress_prefixes,
        'file|f=s' => \$input_file,
        'case-sensitive|c' => \$case_sensitive,
        'table|t' => \$table_output,
        'latex|l' => \$latex_output,
        'help|h' => \$show_help,
    ) or print_usage();
    
    if ($show_help) {
        print_usage();
    }
    
    # Normalize annotation names (ensure they start with @)
    @filter_annotations = map { 
        my $a = $_; 
        $a = '@' . $a unless $a =~ /^@/; 
        $a 
    } @filter_annotations;

    push @filter_annotations, map { '@SuppressWarnings:' . $_ } @suppress_prefixes;
    
    my @inputs = @ARGV;
    
    # If input file is specified, read from it
    if ($input_file) {
        open my $fh, '<', $input_file or do {
            print "Error: Cannot open input file '$input_file': $!\n\n";
            print_usage();
        };
        
        while (my $line = <$fh>) {
            chomp $line;
            $line =~ s/^\x{FEFF}//;  # Remove optional UTF-8 BOM
            $line =~ s/\r$//;        # Normalize CRLF line endings
            # Trim leading/trailing whitespace before comment checks
            $line =~ s/^\s+|\s+$//g;
            # Skip blank lines and pure comment lines
            next if $line eq '' || $line =~ /^(?:#|\/\/)/;
            push @inputs, $line;
        }
        close $fh;
    }
    
    if (!@inputs) {
        print "Error: No input files or directories specified.\n\n";
        print_usage();
    }
    
    # Process each input
    foreach my $input (@inputs) {
        if (-f $input) {
            count_annotations_in_file($input);
        } elsif (-d $input) {
            find({ wanted => \&process_file, no_chdir => 1 }, $input);
        } else {
            warn "Cannot access: $input\n";
        }
    }
    
    # Print results
    print_results();
}

sub print_results {
    # Use table format if requested
    if ($table_output) {
        print_table_results();
        return;
    }
    
    # Use LaTeX format if requested
    if ($latex_output) {
        print_latex_results();
        return;
    }
    
    print "\n";
    print "=" x 80, "\n";
    print "Java Annotation Count Report\n";
    print "=" x 80, "\n";
    print "Total files with annotations: $total_files\n";
    print "Total annotations found: $total_annotations\n";
    print "\n";
    
    if (%annotation_counts) {
        print "-" x 80, "\n";
        print "Annotation Summary (by type)\n";
        print "-" x 80, "\n";
        printf "%-50s %10s\n", "Annotation", "Count";
        print "-" x 80, "\n";
        
        foreach my $annotation (sort { $annotation_counts{$b} <=> $annotation_counts{$a} } 
                                keys %annotation_counts) {
            printf "%-50s %10d\n", $annotation, $annotation_counts{$annotation};
        }
        print "-" x 80, "\n";
        print "\n";
        
        # Print per-file breakdown
        print "-" x 80, "\n";
        print "Per-File Annotation Details\n";
        print "-" x 80, "\n";
        
        foreach my $file (sort keys %file_annotation_counts) {
            my $count = $file_annotation_counts{$file}{count};
            my $annotations = $file_annotation_counts{$file}{annotations};
            
            print "\nFile: $file\n";
            print "  Total annotations: $count\n";
            print "  Breakdown:\n";
            
            foreach my $annotation (sort { $annotations->{$b} <=> $annotations->{$a} } 
                                    keys %{$annotations}) {
                printf "    %-40s : %5d\n", $annotation, $annotations->{$annotation};
            }
        }
        print "\n";
    } else {
        print "No annotations found.\n";
    }
}

sub print_table_results {
    # Generate table output with files as rows and filtered annotations as columns
    
    if (!@filter_annotations) {
        print "Note: Table format works best with specific annotations (-a option).\n";
        print "Please specify annotations with: -a \@Annotation1 -a \@Annotation2\n\n";
        return;
    }
    
    # Build the table
    my @files = sort keys %file_annotation_counts;
    
    if (!@files) {
        print "No annotations found.\n";
        return;
    }
    
    # Header row with filename, LOC, and each annotation
    print "File,LOC,";
    print join(',', @filter_annotations);
    print "\n";
    
    # Track totals
    my $total_loc = 0;
    my %annotation_totals = map { $_ => 0 } @filter_annotations;
    
    # Data rows
    foreach my $file (@files) {
        my $file_data = $file_annotation_counts{$file};
        my $annotations = $file_data->{annotations};
        my $loc = $file_data->{loc} // 0;
        
        # Extract just the filename
        my $filename = $file;
        $filename =~ s/.*\///;  # Remove directory path
        
        # Escape quotes in filename for CSV
        $filename =~ s/"/""/g;
        $filename = '"' . $filename . '"' if $filename =~ /[,"\n]/;
        
        print $filename;
        print ",$loc";
        
        # Add to LOC total
        $total_loc += $loc;
        
        # Count for each annotation
        foreach my $annotation (@filter_annotations) {
            my $count = $annotations->{$annotation} // 0;
            print ",";
            print $count;
            $annotation_totals{$annotation} += $count;
        }
        print "\n";
    }
    
    # Print total row
    print "Total,$total_loc";
    foreach my $annotation (@filter_annotations) {
        print ",";
        print $annotation_totals{$annotation};
    }
    print "\n";
    
    print "\n";
    print "Total files: ", scalar(@files), "\n";
}

sub print_latex_results {
    # Generate LaTeX table output with files as rows and filtered annotations as columns
    
    if (!@filter_annotations) {
        print "Note: LaTeX format works best with specific annotations (-a option).\n";
        print "Please specify annotations with: -a \@Annotation1 -a \@Annotation2\n\n";
        return;
    }
    
    # Build the table
    my @files = sort keys %file_annotation_counts;
    
    if (!@files) {
        print "No annotations found.\n";
        return;
    }
    
    # Create column specification
    my $num_cols = 2 + scalar(@filter_annotations);  # File, LOC, + annotations
    my $col_spec = 'l' . ('r' x ($num_cols - 1));
    
    # Print LaTeX table header
    print "\\begin{table}[h]\n";
    print "\\centering\n";
    print "\\begin{tabular}{" . $col_spec . "}\n";
    print "\\hline\n";
    
    # Header row with filename, LOC, and each annotation
    print "File & LOC";
    foreach my $annotation (@filter_annotations) {
        # Clean up annotation name for LaTeX (remove @ symbol)
        my $clean_name = $annotation;
        $clean_name =~ s/@//;
        print " & " . $clean_name;
    }
    print " \\\\\n";
    print "\\hline\n";
    
    # Track totals
    my $total_loc = 0;
    my %annotation_totals = map { $_ => 0 } @filter_annotations;
    
    # Data rows
    foreach my $file (@files) {
        my $file_data = $file_annotation_counts{$file};
        my $annotations = $file_data->{annotations};
        my $loc = $file_data->{loc} // 0;
        
        # Extract just the filename
        my $filename = $file;
        $filename =~ s/.*\///;  # Remove directory path
        
        # Escape LaTeX special characters
        $filename =~ s/([\\_&%\$#\{\}~])/\\$1/g;
        
        print $filename;
        print " & " . $loc;
        
        # Add to LOC total
        $total_loc += $loc;
        
        # Count for each annotation
        foreach my $annotation (@filter_annotations) {
            my $count = $annotations->{$annotation} // 0;
            print " & " . $count;
            $annotation_totals{$annotation} += $count;
        }
        print " \\\\\n";
    }
    
    # Print total row
    print "\\hline\n";
    print "Total";
    print " & " . $total_loc;
    foreach my $annotation (@filter_annotations) {
        print " & " . $annotation_totals{$annotation};
    }
    print " \\\\\n";
    print "\\hline\n";
    
    # Print LaTeX table footer
    print "\\end{tabular}\n";
    print "\\end{table}\n";
}

# Run the main program
main();
