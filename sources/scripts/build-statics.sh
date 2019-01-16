############################################
################# set vars #################

glyphsSource="sources/sources-buildready/Signika-MM-prepped_designspace.glyphs"

# ## if the Glyphs source has a non-rectangular master/instance arrangement, this fixes it (WIP)
# fixGlyphsDesignspace=true

################# set vars #################
############################################

# ============================================================================
# Generate Variable Font =====================================================

pwd

echo $glyphsSource

tempGlyphsSource=${glyphsSource/".glyphs"/"-build.glyphs"}

## copy Glyphs file into temp file
cp $glyphsSource $tempGlyphsSource

## call fontmake to make all the static fonts
fontmake -g ${tempGlyphsSource} --output ttf --interpolate --overlaps-backend booleanOperations
## OR to just make one static font, as a test, use:
# fontmake -g sources/sources-buildready/Signika-MM-prepped_designspace.glyphs -i "Signika Bold" --output ttf --overlaps-backend booleanOperations

## clean up temp glyphs file
rm -rf $tempGlyphsSource

# python sources/scripts/helpers/shorten-nameID-4-6.py instance_ttf


# ============================================================================
# SmallCap subsetting ========================================================


# TODO?: get this dynamically
ttx instance_ttf/Signika-Bold.ttf
ttxPath="instance_ttf/Signika-Bold.ttx"

#get glyph names, minus .smcp glyphs
subsetGlyphNames=`python sources/scripts/helpers/get-smallcap-subset-glyphnames.py $ttxPath`
rm -rf $ttxPath

echo $subsetGlyphNames

for file in instance_ttf/*; do 
if [ -f "$file" ]; then 

    smallCapFile=${file/"Signika"/"SignikaSC"}

    if [[ $file != *"SignikaNegative-"* ]]; then
        smallCapFile=${file/"Signika"/"SignikaSC"}
    fi
    if [[ $file == *"SignikaNegative-"* ]]; then
        smallCapFile=${file/"SignikaNegative"/"SignikaNegativeSC"}
    fi

    pyftfeatfreeze.py -f 'smcp' -S -U SC $file $smallCapFile
    
    echo "subsetting smallcap font"
    # subsetting with subsetGlyphNames list
    pyftsubset $smallCapFile $subsetGlyphNames --glyph-names

    subsetSmallCapFile=${smallCapFile/".ttf"/".subset.ttf"}
    rm -rf $smallCapFile
    mv $subsetSmallCapFile $smallCapFile

    # 🚨 TODO: update SC font family name with TTX patch
fi 
done


# ============================================================================
# Autohinting ================================================================

for file in instance_ttf/*; do 
if [ -f "$file" ]; then 
    echo "fix DSIG in " ${file}
    gftools fix-dsig --autofix ${file}

    echo "TTFautohint " ${file}
    # autohint with detailed info
    hintedFile=${file/".ttf"/"-hinted.ttf"}
    ttfautohint -I ${file} ${hintedFile} --increase-x-height 9 --stem-width-mode nnn
    cp ${hintedFile} ${file}
    rm -rf ${hintedFile}
fi 
done

# ============================================================================
# OpenType table fixes =======================================================

for file in instance_ttf/*; do 
if [ -f "$file" ]; then 
    ttxPath=${file/".ttf"/".ttx"}
    ## sets up temp ttx file to insert correct values into tables # also drops MVAR table to fix vertical metrics issue
    ttx -x "MVAR" $file
    rm -rf $file
    ## copies temp ttx file back into a new ttf file
    ttx $ttxPath
    rm -rf $ttxPath
fi
done

# ============================================================================
# Sort into final folder =====================================================

# fontbakeFile()
# {
#     FILEPATH=$1
#     fontbakery check-googlefonts ${FILEPATH} --ghmarkdown ${FILEPATH/".ttf"/"-fontbakery-report.md"}
# }

outputDir="fonts"

for file in instance_ttf/*; do 
if [ -f "$file" ]; then 
    fileName=$(basename $file)
    echo $fileName
    if [[ $file == *"Signika-"* ]]; then
        newDirectory=signika
    fi
    if [[ $file == *"SignikaNegative-"* ]]; then
        newDirectory=signikanegative
    fi
    if [[ $file == *"SignikaSC-"* ]]; then
        newDirectory=signikasc
    fi
    if [[ $file == *"SignikaNegativeSC-"* ]]; then
        newDirectory=signikanegativesc
    fi

    newPath=$outputDir/$newDirectory/static/$fileName
    cp ${file} ${newPath}
        
    fontbakePath=$outputDir/$newDirectory/static/fontbakery-checks/${fileName/".ttf"/"-fontbakery_checks.md"}
    fontbakeFile $newPath $fontbakePath

    fontbakery check-googlefonts $file --ghmarkdown $fontbakePath
fi 
done

# # clean up build folders
rm -rf instance_ufo
# rm -rf instance_ttf
rm -rf master_ufo