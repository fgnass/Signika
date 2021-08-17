# Set bash to exit on errors and print all commands
set -x -e

source="sources/sources-buildready/Signika-MM-prepped_designspace.glyphs"
pathNOSC="fonts/signikavf/Signika[NEGA,wght].ttf"
pathSC="fonts/signikavfsc/SignikaSC[NEGA,wght].ttf"
tmp="variable_ttf/Signika-VF.ttf"
tmpSC="variable_ttf/Signika-VFSC.ttf"
dsPath="master_ufo/Signika.designspace"

#------------------------------------------------------------------------------
# Remove previous build folder
#------------------------------------------------------------------------------
if [ -d "variable_ttf" ]; then
  rm -rf variable_ttf
fi
if [ -d "master_ufo" ]; then
  rm -rf variable_ttf
fi
if [ -d "instance_ufo" ]; then
  rm -rf variable_ttf
fi

rm -rf dsPath


#------------------------------------------------------------------------------
# Compile from sources
#------------------------------------------------------------------------------
# make temp glyphs file with "-build" suffix
tmpSource=${source/".glyphs"/"-Build.glyphs"}

# copy Glyphs file into temp file
cp $source $tmpSource
fontmake -g $tmpSource -o variable

# Replace the TTF VFs name table entries which inherit from the Light master
python sources/scripts/helpers/replace-family-name.py $tmp "Signika Light" "Signika"


#------------------------------------------------------------------------------
# Smallcap subsetting
#------------------------------------------------------------------------------

# Making a SC "frozen" font
# This mapps all smcp glyphs to their "substitute" and also renames their names with suffix "SC"
python sources/scripts/helpers/pyftfeatfreeze.py -f 'smcp' $tmp $tmpSC

# Removing SC from the font
# This removes the smcp features and involved glyphs
echo "subsetting smallcap font"
echo $tmpSC
pyftsubset $tmpSC --unicodes="*" --name-IDs='*' --glyph-names --layout-features="*" --layout-features-="smcp" --recalc-bounds --recalc-average-width --notdef-glyph --notdef-outline

# Replace the SC file with the pyftsubset generated .subset file
rm -rf $tmpSC
mv ${tmpSC/".ttf"/".subset.ttf"} $tmpSC

#--------------------------------------------------------------------------
# Update names in font with smallcaps suffix
#--------------------------------------------------------------------------
python sources/scripts/helpers/replace-family-name.py "$tmpSC" "Signika" "Signika SC"


# Some QA post-processing on all generated fonts
for file in variable_ttf/*; do 
if [ -f "$file" ]; then

    #--------------------------------------------------------------------------
    # Fix DSIG
    #--------------------------------------------------------------------------
    echo "Fix DSIG in " ${file}
    file="${file}"
    gftools fix-dsig --autofix ${file}


    # 12.06.2020 Disabled VF autohinting for now, since results are not 
    # satisfactory
    # #--------------------------------------------------------------------------
    # # Autohint with detailed info
    # #--------------------------------------------------------------------------
    # echo "TTFautohint ${file}" 
    # hintedFile=${file/".ttf"/"-hinted.ttf"}

    # ./sources/scripts/helpers/ttfautohint-vf -I $file $hintedFile --stem-width-mode nnn --increase-x-height 9
    # gftools fix-hinting $hintedFile # will create a file suffixed with .fix
    # fixedFile="${hintedFile}.fix"
    # cp $fixedFile $file # copy back to original ttf

    # rm -rf $hintedFile # remove the -hinted.ttf file
    # rm -rf $fixedFile # remove the -hinted.ttf.fix file
    
    # 12.06.2020 Instead of autohinting, use gftools to fix up the unhinted 
    # files
    gftools fix-nonhinting ${file} ${file}


    #--------------------------------------------------------------------------
    # Various fixes MVAR
    #--------------------------------------------------------------------------
    echo "Fix MVAR and other name tables in ${file}"
    gftools fix-unwanted-tables $file

fi 
done


#------------------------------------------------------------------------------
# Copy to final location
#------------------------------------------------------------------------------
echo "Copy $tmp to output location $path"
cp $tmp $pathNOSC
echo "Copy $tmpSC to output location $pathSC"
cp $tmpSC $pathSC


#------------------------------------------------------------------------------
# Run fontbakery checks on the final files
#------------------------------------------------------------------------------
echo "Run fontbakery checks"
# Exclude the static folder check; not relevant in this source repo
fontbakery check-googlefonts $pathNOSC --exclude-checkid "com.google.fonts/check/repo/vf_has_static_fonts" --ghmarkdown "fonts/signikavf/fontbakery-checks/Signika[NEGA,wght]-fontbakery-report.md"
fontbakery check-googlefonts $pathSC --exclude-checkid "com.google.fonts/check/repo/vf_has_static_fonts" --ghmarkdown "fonts/signikavfsc/fontbakery-checks/SignikaSC[NEGA,wght]-fontbakery-report.md"
