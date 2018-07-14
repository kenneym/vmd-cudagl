#
# $Id: qwikmd.tcl,v 1.64 2017/10/25 18:30:30 jribeiro Exp $
#
#==============================================================================
# QwikMD
#
# Authors:
#   João V. Ribeiro
#   Beckman Institute for Advanced Science and Technology
#   University of Illinois, Urbana-Champaign
#   jribeiro@ks.uiuc.edu
#   http://www.ks.uiuc.edu/~jribeiro
#
#   Rafael C. Bernardi
#   Beckman Institute for Advanced Science and Technology
#   University of Illinois, Urbana-Champaign
#   rcbernardi@ks.uiuc.edu
#   http://www.ks.uiuc.edu/~rcbernardi/
#
#   Till Rudack
#   Beckman Institute for Advanced Science and Technology
#   University of Illinois, Urbana-Champaign
#   trudack@ks.uiuc.edu
#   http://www.ks.uiuc.edu/~trudack/
#
# Usage:
#   QwikMD was designed to be used exclusively through its GUI,
#   launched from the "Extensions->Simulation" menu.
#
#   Also see http://www.ks.uiuc.edu/Research/vmd/plugins/qwikmd/ for the
#   accompanying documentation.
#
#=============================================================================

package provide qwikmd 1.2

namespace eval ::QWIKMD:: {
    

    ### Read Packages
    package require Tablelist 
    package require autopsf
    package require Tk 8.5
    package require psfgen
    package require solvate
    package require topotools
    package require pbctools
    package require structurecheck
    package require membrane
    package require readcharmmtop
    package require mdff_gui
    global tcl_platform env

    ##Main GUI Variables


   #variable afterid {}
    #variable delta 0
    #variable maxy 0.0
    #variable maxx 0.0

    variable topGui ".qwikmd"
    variable bindTop 0
    variable topMol ""
    variable inputstrct ""
    variable nmrstep ""
    ################################################################################
    ## QWIKMD::chains(index "Select chain/type",indexes)
    ## contains information about the chain and keep track the initial chains and types in the pdb
    ## QWIKMD::chains(index "Select chain/type",0) -- boolean if it is select or not in "Select chain/type" menu
    ## QWIKMD::chains(index "Select chain/type",1) -- label in the "Select chain/type" dropdown menu
    ## QWIKMD::chains(index "Select chain/type",2) -- residues ids range
    ################################################################################
    array set chains ""
    ################################################################################
    ## QWIKMD::index_cmb
    ## contains information about the chain and the comboboxs in the main table
    ## QWIKMD::index_cmb($chain and $type,1) -- representation mode
    ## QWIKMD::index_cmb($chain and $type,2) -- color mode
    ## QWIKMD::index_cmb($chain and $type,3) -- index in the "Select chain/type" menu
    ## QWIKMD::index_cmb($chain and $type,4) -- main table color combobox path in the GUI
    ## QWIKMD::index_cmb($chain and $type,5) -- atomselection for that (chain and type) entry
    ################################################################################
    array set index_cmb ""
    array set cmb_type ""
    # variables equi, md and smd were depicted after the vmd 1.9.3 beta 3. Now is included in the basicGui array.
    # Kept in here for compatibility issues. 
    # Remove after all users switched to newer versions.
    variable equi 1
    variable md 1
    variable smd 1
    variable colorIdMap {{ResName} {ResType} {Name} {Element} {Structure} {Throb} {0 blue} {1 red} {2 gray} {3 orange} {4 yellow} \
    {5 tan} {6 silver} {7 green} {8 white} {9 pink} {10 cyan} {11 purple} {12 lime} {13 mauve} {14 ochre} {15 iceblue}\
     {16 black} {17 yellow2} {18 yellow3} {19 green2} {20 green3} {21 cyan2} {22 cyan3} {23 blue2} {24 blue3}\
         {25 violet} {26 violet2} {27 magenta} {28 magenta2} {29 red2} {30 red3} {31 orange2} {32 orange3} }
    variable outPath ""
    ################################################################################
    ## QWIKMD::basicGui
    ## stores widgets variables (name,0), and widgets path (name,1) if necessary
    ## QWIKMD::basicGui(solvent,$QWIKMD::run,0) - solvent combobox
    ## QWIKMD::basicGui(solvent,boxbuffer,$QWIKMD::run) - solvent box buffer
    ## QWIKMD::basicGui(saltconc,$QWIKMD::run,0) - concentration entry
    ## QWIKMD::basicGui(saltions,$QWIKMD::run) - "choose salt" combobox
    ## QWIKMD::basicGui(temperature,$QWIKMD::run,0) -  temperature entry
    ## QWIKMD::basicGui(pspeed) - smd pulling speed
    ## QWIKMD::basicGui(plength) - smd pulling length
    ## QWIKMD::basicGui(mdtime,0) - MD simulation time
    ## QWIKMD::basicGui(mdtime,1) - SMD simulation time
    ## QWIKMD::basicGui(workdir,0) - working directory
    ## QWIKMD::basicGui(desktop) - desktop color selection
    ## QWIKMD::basicGui(scheme) - VMD scheme
    ## QWIKMD::basicGui(live,0) - live simulation boolean selection in basic tab
    ## QWIKMD::basicGui(live,1) - live simulation boolean selection in advanced tab
    ## QWIKMD::basicGui(mdPrec,0) - live simulation boolean selection
    ## QWIKMD::basicGui(currenttime) - label for current Simulation time
    ################################################################################
    array set basicGui ""
    ################################################################################
    ## QWIKMD::advGui(addmol) - add number of molecules
    ## QWIKMD::advGui(saltconc,$QWIKMD::run,0)- concentration entry
    ## QWIKMD::advGui(saltions,$QWIKMD::run) - "choose salt" combobox
    ## QWIKMD::advGui(protocoltb,$QWIKMD::run) - table containing the protocol in Advanced Run Tab
    ## QWIKMD::advGui(protocoltb,index)- info about save as popup window
    ## QWIKMD::advGui(protocoltb,index,saveAsTemplate)- info about save as popup window
    ## QWIKMD::advGui(protocoltb,index,smd)- is smd?
    ## QWIKMD::advGui(protocoltb,index,lock)- is this protocol locked
    ## QWIKMD::advGui(analyze,level,?)- stores Guis values and path of analyze frames
    ## QWIKMD::advGui(analyze,advance,calcombo)- stores calculation combobox value in advanced analysis 
    ## QWIKMD::advGui(analyze,advance,calcbutton)- stores the path of the "Calculate" button in advanced analysis 
    ## QWIKMD::advGui(analyze,advanceframe)- stores the path of advance frame 
    ## QWIKMD::advGui(analyze,advance,qtmeptbl)- table present in temperature quench
    ## QWIKMD::advGui(analyze,advance,decayentry)- value of the autocorrelation decay time
    ################################################################################
    ## schmColor stores the RBG values for the new color schemes
    array set schmColor {
        Neutral {
            {blue     {212 255 253}}
            {red      {209 116 90}}
            {gray     {109 130 120}}
            {orange   {255 219 176}}
            {yellow   {242 227 148}}
            {tan      {242 174 114}}
            {silver   {217 213 204}}
            {green    {250 252 212}}
            {white    {255 255 255}}
            {pink     {217 106 115}}
            {cyan     {52  209 196}}
            {purple   {53  45  64}}
            {lime     {233 255 199}}
            {mauve    {166 159 162}}
            {ochre    {170 153 136}}
            {iceblue  {199 224 207}}
            {black    {0   0   0}}
            {yellow2  {255 244 185}}
            {yellow3  {242 224 131}}
            {green2   {222 222 133}}
            {green3   {166 166 94}}
            {cyan2    {154 242 238}}
            {cyan3    {188 241 237}}
            {blue2    {149 191 191}}
            {blue3    {220 242 234}}
            {violet   {155 170 193}}
            {violet2  {84  64  68}}
            {magenta  {217 102 111}}
            {magenta2 {169 6   65}}
            {red2     {217 45  7}}
            {red3     {166 33  3}}
            {orange2  {220 55  34}}
            {orange3  {255 165 49}}
        }
        QwikMD {
            {blue     {38  58  189}}
            {red      {184 29  32}}
            {gray     {210 210 210}}
            {orange   {209 94  13}}
            {yellow   {255 251 143}}
            {tan      {120 83  52}}
            {silver   {230 230 230}}
            {green    {48  186 67}}
            {white    {255 255 255}}
            {pink     {242 133 133}}
            {cyan     {157 242 241}}
            {purple   {97  45  166}}
            {lime     {153 199 74}}
            {mauve    {94  82  40}}
            {ochre    {97  81  48}}
            {iceblue  {235 247 255}}
            {black    {0   0   0}}
            {yellow2  {235 237 100}}
            {yellow3  {211 214 2}}
            {green2   {2   214 30}}
            {green3   {79  168 91}}
            {cyan2    {33  177 209}}
            {cyan3    {29  155 184}}
            {blue2    {57  129 189}}
            {blue3    {75  138 209}}
            {violet   {127 75  209}}
            {violet2  {154 108 235}}
            {magenta  {235 108 207}}
            {magenta2 {235 84  202}}
            {red2     {222 87  89}}
            {red3     {209 33  36}}
            {orange2  {209 66  33}}
            {orange3  {235 137 0}}
        }
        80s {
            {blue     {0   0   171}}
            {red      {175 0   0}}
            {gray     {74  74  74}}
            {orange   {252 126 0}}
            {yellow   {242 250 0}}
            {tan      {176 88  0}}
            {silver   {176 176 176}}
            {green    {128 255 0}}
            {white    {255 255 255}}
            {pink     {255 96  64}}
            {cyan     {0   195 255}}
            {purple   {101 13  105}}
            {lime     {167 250 0}}
            {mauve    {169 174 0}}
            {ochre    {179 116 126}}
            {iceblue  {180 200 237}}
            {black    {0   0   0}}
            {yellow2  {243 255 112}}
            {yellow3  {234 255 25}}
            {green2   {116 173 0}}
            {green3   {0   174 0}}
            {cyan2    {105 182 245}}
            {cyan3    {105 235 245}}
            {blue2    {68  68  171}}
            {blue3    {0   0   94}}
            {violet   {118 73  214}}
            {violet2  {82  19  145}}
            {magenta  {222 33  115}}
            {magenta2 {222 33  190}}
            {red2     {235 49  49}}
            {red3     {204 0   3}}
            {orange2  {204 150 0}}
            {orange3  {250 92  0}}
        }
        Pastel {
            {blue     {111 183 214}}
            {red      {252 169 133}}
            {gray     {197 195 199}}
            {orange   {253 202 162}}
            {yellow   {255 255 176}}
            {tan      {219 213 185}}
            {silver   {193 190 197}}
            {green    {224 243 176}}
            {white    {255 255 255}}
            {pink     {253 222 238}}
            {cyan     {204 236 239}}
            {purple   {165 137 193}}
            {lime     {181 225 174}}
            {mauve    {204 204 198}}
            {ochre    {77  77  62}}
            {iceblue  {191 213 232}}
            {black    {0   0   0}}
            {yellow2  {255 250 129}}
            {yellow3  {255 237 81}}
            {green2   {134 207 190}}
            {green3   {72  181 163}}
            {cyan2    {88  127 167}}
            {cyan3    {166 189 219}}
            {blue2    {123 156 169}}
            {blue3    {217 229 240}}
            {violet   {221 212 232}}
            {violet2  {193 179 215}}
            {magenta  {251 182 209}}
            {magenta2 {249 140 182}}
            {red2     {203 174 170}}
            {red3     {255 232 232}}
            {orange2  {255 215 119}}
            {orange3  {255 158 72}}
        }
    }

    array set advGui ""
    variable runbtt [list]
    variable pausebtt [list]
    variable detachbtt [list]
    variable finishbtt [list]
    variable resetbttwgt [list]
    variable loadpdb [list]
    variable autorenamebtt [list]
    variable autorename 1
    variable autorenameLog [list]
    variable loadqwikmd [list]
    variable nmrMenu [list]
    variable chainMenu [list]
    variable preparebtt [list]
    variable livebtt [list]
    #missing the work directory

    #variable preparebtt ""
    ### var notebooks list of notebooks used mainly to delete remaining plot 
    variable notebooks ""
    ### var selnotbooks list of the {notebook tabid} to keep store which (basic/advanced run)
    ### and which tab was selected for preparation
    variable selnotbooks [list]
    ####ConfFile stores the protocols created or the protocols selected to be loaded after running the simulations
    #### prevconffile stores the list of all protocols created and saved in the qwikmd inputfile
    variable wmgeom ""
    variable confFile ""
    variable prevconfFile ""
    variable cellDim ""
    variable logo ""
    variable state 0
    variable stop 1 
    variable load 0
    variable run MD
    variable runstep 0
    variable combovalues ""
    variable selected 1
    variable anchorpulling 0
    variable buttanchor 0
    array set color ""
    variable anchorRes ""
    variable pullingRes ""
    variable anchorRessel ""
    variable pullingRessel ""
    variable showanchor 0
    variable showpull 0
    variable ts 0
    variable restts 0
    variable lastframe ""
    variable viewpoints ""
    variable calcfreq 20
    variable smdfreq 40
    variable dcdfreq 1000
    variable timestep 2
    variable imdFreq 10
    variable hbondsprevx 0
    variable prepared 0
    variable inpFile ""
    variable showMdOpt 0
    variable bgcolor [ttk::style lookup TFrame -background]
    # atom selection macros to store the definition of protein, nucleic, glycan (carbohydrates) and heteroatoms. This ensures
    # that QwikMD follows the definition of each molecule types set by the user.
    # QWIKMDDELETE is used to rename the atoms to be deleted in the QWIKMD::deleteAtoms proc, Edit Atoms Windows.
    # AutoPSF and Torsion plot are aware of these macros
    variable proteinmcr "(not name QWIKMDDELETE and protein)"
    variable nucleicmcr "(not name QWIKMDDELETE and nucleic)"
    variable glycanmcr "(not name QWIKMDDELETE and glycan)"
    variable lipidmcr "(not name QWIKMDDELETE and lipid)"
    variable heteromcr "(not name QWIKMDDELETE and hetero and not qwikmd_protein and not qwikmd_lipid and not qwikmd_nucleic and not qwikmd_glycan and not water)"
    atomselect macro qwikmd_protein $proteinmcr
    atomselect macro qwikmd_nucleic $nucleicmcr
    atomselect macro qwikmd_glycan $glycanmcr
    atomselect macro qwikmd_lipid $lipidmcr
    atomselect macro qwikmd_hetero $heteromcr

    variable prtclSelected -1

    array set mdProtInfo ""

    variable refIndex [list]
    variable references [list]
    #variable renumber [list]
    variable textLogfile ""

    ##Select Residue GUI Variables
    variable selResidSel ""
    variable selResidSelIndex [list]
    # variable for message window
    variable messWinGui ".qwikmdMesWin"
    # variable selResidSelRep ""
    variable selResGui ".qwikmdResGui"
    variable selresTable ""
    variable selresPatcheFrame ""
    variable selresPatcheText ""
    variable patchestr ""
    array set protres ""
    variable tablemode "inspection"
    variable prevRes ""
    variable prevtype ""
    variable delete ""
    variable rename ""
    array set mutate ""
    variable mutindex ""
    array set protonate ""
    variable protindex ""
    array set dorename ""
    variable renameindex ""
    variable resrepname ""
    variable residtbprev ""
    variable anchorrepname ""
    variable pullingrepname ""
    # Default residues list known to QwikMD. To add more to this list through the GUI, one has to add Topology files
    # using the Add topo+param button
    variable reslist {ALA ARG ASN ASP CYS GLN GLU GLY HSD ILE LEU LYS MET PHE PRO SER THR TRP TYR VAL HSP HSE}
    variable hetero {ACET ACO ADP AMM1 AMP ATP BAR CD2 CAL CES CLA ETOH OH LIT MG NAD NADH NADP NDPH POT PYRM RUB SOD ZN2}
    variable heteronames {{Acetate} {Acetone} {ADP} {Ammonia} {AMP} {ATP} {Barium} {Cadmium II} {Calcium} {Cesium} {Chloride} {Ethanol} {Hydroxide} {Lithium} {Magnesium} \
    {NAD} {NADH} {NADP} {NDPH} {Potassium} {Pyrimidine} {Rubidium} {Sodium} {Zinc 2}}

    variable carb {AGLC BGLC AALT BALT AALL BALL AGAL BGAL AGUL BGUL AIDO BIDO AMAN BMAN ATAL BTAL AXYL BXYL AFUC BFUC ARHM BRHM}
    variable carbnames {{4C1 alpha-D-glucose} {4C1 beta-D-glucose} {4C1 alpha-D-altrose} {4C1 beta-D-altrose} {4C1 alpha-D-allose} {4C1 beta-D-allose} {4C1 alpha-D-galactose} {4C1 beta-D-galactose}\
     {4C1 alpha-D-gulose} {4C1 beta-D-gulose} {4C1 alpha-D-idose} {4C1 beta-D-idose} {4C1 alpha-D-mannos} {4C1 beta-D-mannose} {4C1 alpha-D-talose} \
    {4C1 beta-D-talose} {alpha-D-xylose} {beta-D-xylose} {alpha-L-fucose} {beta-L-fucose} {alpha-L-rhamnose} {beta-L-rhamnose}}
    variable nucleic {GUA ADE CYT THY URA}
    variable lipidname {LPPC DLPC DLPE DLPS DLPA DLPG DMPC DMPE DMPS DMPA DMPG DPPC DPPE DPPS DPPA DPPG DSPC DSPE DSPS DSPA DSPG DOPC DOPE DOPS DOPA DOPG POPC POPE POPS POPA POPG SAPC SDPC SOPC DAPC}

    ## elements array to be used to construct the "fake" topology file
    ## format : {element "Atom Type"} 
    array set element {}
    set element(H) "H";       # alphatic proton, CH
    set element(Fe) "FE";      # heme iron 56
    set element(C) "C";       # carbonyl C, peptide backbone
    set element(N) "N";       # peptide nitrogen (CO=NHR)
    set element(O) "O";       # carbonyl O: amides, esters, [neutral] carboxylic acids, aldehydes, uera
    set element(S) "S";       # thiocarbonyl S
    set element(P) "P";       # phosphorus
    set element(He) "HE";     # helium
    set element(Ne) "NE";     # neon
    set element(LI) "LIT";    # Lithium ion
    set element(NA) "SOD";    # Sodium Ion
    set element(MG) "MG";     # Magnesium Ion
    set element(K) "POT" ;    # Potassium Ion
    set element(CA) "CAL";    # Calcium Ion
    set element(RB) "RUB";    # Rubidium Ion
    set element(CS) "CES";    # Cesium Ion
    set element(BA) "BAR";    # Barium Ion
    set element(ZN) "ZN";     # zinc (II) cation
    set element(CD) "CAD";    # cadmium (II) cation
    set element(CL) "CLA";    # Chloride Ion
    set element(Cl) "CLGA1";  # CLET, DCLE, chloroethane, 1,1-dichloroethane
    set element(Br) "BRGA1";  # BRET, bromoethane
    set element(I) "IGR1";    # IODB, iodobenzene
    set element(F) "FGA1";    # aliphatic fluorine, monofluoro
    set element(Al) "ALG1";      # Aluminum, for ALF4, AlF4-
    

    variable numProcs ""
    variable gpu 1
    variable mdPrec 0
    variable maxSteps [list]
    set warnresid 0
    # variables to store the values return by QWIKMD::checkStructur proc.
    # topology errors (missing) are evaluated by QwikMD 
    # chirality, cispeptide and Ramachandran plot torsion errors are evaluated by strctcheck plugin 
    variable topoerror ""
    variable topolabel ""
    variable topocolor ""
    variable chirerror ""
    variable chirlabel ""
    variable chircolor ""

    variable cisperror ""
    variable cisplabel ""
    variable cispcolor ""

    variable gaps ""    
    variable gapslabel ""
    variable gapscolor ""

    variable torsionOutlier ""  
    variable torsionOutliearlabel ""
    variable torsionOutliearcolor ""
    variable torsionTotalResidue 0

    variable torsionMarginal "" 
    variable torsionMarginallabel ""
    variable torsionMarginalcolor ""

    variable tabprev -1
    variable tabprevmodf -1
    variable tabprevanaly -1
    variable resallnametype 1
    ##Edit Atoms GUI Variables
    variable editATMSGui ".qwikmdeditAtm"
    variable atmsTable ""
    variable atmsText ""
    variable atmsNames ""
    variable atmsOrigNames ""
    variable atmsOrigIdex ""
    variable atmsOrigElem ""
    variable atmsMol ""
    variable atmsLables ""
    variable atmsDeleteNames [list]
    variable atmsRename [list]
    variable atmsOrigResid [list]
    variable charmTopoInfo [list]
    variable atmsRenameLog [list]
    variable atmsElemLog [list]
    variable atmsDeleteLog [list]
    variable atmsReorderLog [list]
    variable topofilename ""
    variable totcharge 0.00
    #####################################
    ## List of lists defining the user specific parameters and
    ## macros atom selection
    ## each list :
    ##      index 0 - macro name/molecule type
    ##      index 1 - list of Charmm resdues names
    ##      index 2 - list of user resdues denomination
    ## 
    variable userMacros [list]
    array set topocombolist ""
    ##Select TOPO+PARAM GUI Variables
    variable topoPARAMGUI ".qwikmdTopoParam"
    variable topparmTable ""
    variable topparmTableError 0
    # motion indicators (from FFTK GUI)
    # tree element open and close indicators
    set downPoint \u25BC
    set rightPoint \u25B6
    set tempEntry "#696969"

    ##Loading Option Window
    variable loadremovewater 0
    variable loadremoveions 0
    variable loadremovehydrogen 0
    variable loadinitialstruct 0
    variable loadstride 1
    variable strdentry ""
    variable loadlaststep 0
    variable curframe -1
    variable loadprotlist [list]
    ##RMSD Plot Variables
    
    variable rmsdGui ""
    
    variable rmsdsel "backbone"
    variable rmsdseltext "protein"
    set line ""
    variable timeXrmsd 0
    variable rmsd 0
    variable rmsdprevx 0
    variable lastrmsd -1
    variable counterts 0
    variable prevcounterts 0
    variable rmsdplotview 0
    ##Hydrogen Plot Variables
    
    variable HBondsGui ""
    variable hbondsGui ""
    variable lasthbond -1
    variable hbonds ""
    variable timeXhbonds ""
    variable hbondssel "intra"
    variable hbondsplotview 0
    variable hbondsrepname ""
    ##Energies Plot Variables
    
    variable energyTotGui ""
    variable energyKineGui ""
    variable energyElectGui ""
    variable energyPotGui ""
    variable energyBondGui ""
    variable energyAngleGui ""
    variable energyDehidralGui ""
    variable energyVdwGui ""
    
    variable lastenetot -1
    variable lastenekin -1
    variable lastenepot -1
    variable lastenebond -1
    variable lasteneangle -1
    variable lastenedihedral -1
    variable lastenevdw -1

    variable eneprevx 0
    variable enecurrentpos 0
    variable eneprevx 0
    variable enecurrentpos 0
    variable enetotval ""
    variable enetotpos ""
    variable enekinval ""
    variable enekinpos ""
    variable eneelectval ""
    variable eneelectpos ""
    variable enepotval ""
    variable enepotpos ""
    variable enebondval ""
    variable enebondpos ""
    variable eneangleval ""
    variable eneanglepos ""
    variable enedihedralval ""
    variable enedihedralpos ""
    variable enevdwval ""
    variable enevdwpos ""
    variable enerkinetic 0
    variable enertotal 1
    variable enerelect 0
    variable enerpoten 0
    variable eneplotview 0
    variable enerbond 0
    variable enerangle 0
    variable enerdihedral 0 
    variable enervdw 0 
    ##Conditions Plot Variables
    variable tempGui ""
    variable pressGui ""
    variable volGui ""
    variable plotwindowCON ""
    variable CondGui ".qwikmdCONGui"
    variable lasttemp -1
    variable lastpress -1
    variable lastvol -1
    variable tempval ""
    variable temppos ""
    variable pressval ""
    variable pressvalavg ""
    variable presspos ""
    variable volval ""
    variable volvalavg ""
    variable volpos ""
    variable condcurrentpos 0
    variable tempcalc 1
    variable pressurecalc 0
    variable volumecalc 0
    variable condprevx 0
    variable condprevindex 0
    variable condplotview 0
    variable condcurrentpos 0
    ####Tmperature quench variables
    variable radiobtt ""
    variable qtempGui ""
    variable qtempval ""
    variable qtemppos ""
    variable qtemprevx
    ####Maxwell-Boltzmann Energy Distribution variables
    variable MBGui ""
    ####Specific Heat variables
    variable SPHGui ""
    ####Temperature Distribution variables
    variable tempDistGui ""
    ####SASA variables
    variable SASAGui ""
    variable sasarep ""
    variable sasarepTotal1 ""
    variable sasarepTotal2 ""
    ####CSASA variables
    variable CSASAGui ""
    
    ####RMSF variables
    variable rmsfGui ""
    variable rmsfrep ""
    ##SMD Plot Variables
    variable SMDGui ".qwikmdSMDDGui"
    variable smdGui ""
    variable plotwindowSMD ""
    variable lastsmd -1
    variable timeXsmd 0
    variable smdvals 0
    variable smdvalsavg 0
    variable smdfirstdist ""
    variable countertssmd 0
    variable smdxunit "time"
    variable smdcurrentpos 0
    variable smddistance 0
    variable smdplotview 0
    variable smdcurrentpos 0
    variable smddistance 0
    
    variable smdprevindex 0
    variable prevcountertsmd 0
    
    variable membranebox [list]
    variable membraneFrame ""

    variable pbcInfo ""
    
    global env

    set ParameterList [glob $env(CHARMMPARDIR)/*36*.prm]
    set str [glob $env(CHARMMPARDIR)/*.str]
    
    set ParameterList [concat $str $ParameterList]
    
    lappend TopList [file join $env(CHARMMTOPDIR) top_all36_prot.rtf]
    lappend TopList [file join $env(CHARMMTOPDIR) top_all36_lipid.rtf]
    lappend TopList [file join $env(CHARMMTOPDIR) top_all36_na.rtf]
    lappend TopList [file join $env(CHARMMTOPDIR) top_all36_carb.rtf]
    lappend TopList [file join $env(CHARMMTOPDIR) top_all36_cgenff.rtf]
    lappend TopList [file join $env(CHARMMTOPDIR) toppar_all36_carb_glycopeptide.str]
    lappend TopList [file join $env(CHARMMTOPDIR) toppar_water_ions_namd.str]
    for {set i 0} {$i < [llength $str]} {incr i} {
        if {[lsearch $TopList [file tail [lindex $str $i]]] == -1} {
            lappend TopList [lindex $str $i]
        }
    }
    set topoinfo [list]
}

# source the rest of the tcl files (less file management than using package require)
source [file join $env(QWIKMDDIR) qwikmd_func.tcl]
source [file join $env(QWIKMDDIR) qwikmd_info.tcl]
source [file join $env(QWIKMDDIR) qwikmd_logText.tcl]
source [file join $env(QWIKMDDIR) qwikmd_ballon.tcl]

proc qwikmd {} { return [eval QWIKMD::qwikmd]}

## main qwikmd proc
proc QWIKMD::qwikmd {} {
    global env

    if {[winfo exists $QWIKMD::topGui] != 1} {
        QWIKMD::path
        
    } else {
        wm deiconify $QWIKMD::topGui
    }
    raise $QWIKMD::topGui
    set env(QWIKMDTMPDIR) ""
    QWIKMD::checkDeposit
    QWIKMD::resetBtt 2
    wm deiconify $QWIKMD::topGui
    set QWIKMD::wmgeom "[winfo reqwidth $QWIKMD::topGui]x[winfo reqheight $QWIKMD::topGui]"
    return $QWIKMD::topGui
}

############################################################
## The reset command receives an option depending of what is 
## intended to clean:
##       opt = 0 - everything but simulation options and 
##                 strucuture manipulation options (e.g. mutations)
##       
##       opt = 1 - everything but structure manipulation options (e.g. mutations) 
##       
##       opt = 2 - restores qwikMD to the initial state
############################################################


proc QWIKMD::resetBtt {opt} {

    if {$opt > 1} {
        set continue [QWIKMD::checkIMD]
        if {$continue == 0} {
            return 1
        }
    }

    set tabid 0
    if {[llength $QWIKMD::selnotbooks] > 0} {
        set tabid [lindex [lindex $QWIKMD::selnotbooks 0] 1]
    }
    $QWIKMD::topGui.nbinput select $tabid 
    if {$opt > 0} {

        if {[winfo exists $QWIKMD::editATMSGui] == 1} {
            destroy $QWIKMD::editATMSGui
        }
        
        if {[winfo exists $QWIKMD::topoPARAMGUI] == 1} {
            destroy $QWIKMD::topoPARAMGUI
        }
        ## delete the protocol table entries
        ## reset the combobox solvent values
        $QWIKMD::topGui.nbinput.f1.tableframe.tb delete 0 end
        $QWIKMD::topGui.nbinput.f2.tableframe.tb delete 0 end
        set prt {MD SMD "QM/MM"}
        set values {"Vacuum" "Implicit" "Explicit"}
        foreach run $prt {
            $QWIKMD::advGui(protocoltb,$run) delete 0 end
            $QWIKMD::advGui(solvent,$run) configure -values $values
        }
        $QWIKMD::advGui(qmtable) delete 0 end

        $QWIKMD::topGui.nbinput.f1.selframe.mCHAIN.chain delete 0 end
        $QWIKMD::topGui.nbinput.f1.selframe.mNMR.nmr delete 0 end
        $QWIKMD::topGui.nbinput tab 0 -state normal
        $QWIKMD::topGui.nbinput tab 1 -state normal

        # change the notebook tabs states to normal 
        foreach note $QWIKMD::notebooks {
            $note state "!disabled"
        }
        $QWIKMD::basicGui(workdir,1) configure -state normal
        $QWIKMD::basicGui(workdir,2) configure -state normal
        $QWIKMD::topGui.nbinput select 0
        [lindex $QWIKMD::notebooks 1] select 0
        for {set i 0} {$i < 2} {incr i} {
            [lindex $QWIKMD::nmrMenu $i] configure -state normal
            [lindex $QWIKMD::chainMenu $i] configure -state normal
            set QWIKMD::basicGui(live,$i) 0
        }
        # default entry widgets text fonts 
        ttk::style configure WorkDir.TEntry -foreground $QWIKMD::tempEntry
        ttk::style configure RmsdSel.TEntry -foreground $QWIKMD::tempEntry
        ttk::style configure RmsdAli.TEntry -foreground $QWIKMD::tempEntry
        ttk::style configure PdbEntrey.TEntry -foreground $QWIKMD::tempEntry
        set QWIKMD::basicGui(workdir,0) "Working Directory"
        
        set QWIKMD::basicGui(currenttime) "Completed 0.000 of 0.000 ns"
        set QWIKMD::basicGui(mdPrec,0) 0
        set QWIKMD::run MD
        set QWIKMD::confFile ""
        set QWIKMD::prevconfFile ""
        set QWIKMD::cellDim ""
        set QWIKMD::anchorRes ""
        set QWIKMD::anchorrepname ""
        set QWIKMD::pullingrepname ""
        set QWIKMD::pullingRes ""
        set QWIKMD::viewpoints ""
        set QWIKMD::anchorpulling 0
        set QWIKMD::showanchor 0
        set QWIKMD::showpull 0
        set QWIKMD::anchorRessel ""
        set QWIKMD::pullingRessel ""
        set QWIKMD::selResidSel "Type Selection"
        set QWIKMD::selResidSelIndex [list]
        # set QWIKMD::selResidSelRep ""
        set QWIKMD::inputstrct "PDB ID"
        [lindex $QWIKMD::autorenamebtt 0] configure -state normal
        [lindex $QWIKMD::autorenamebtt 1] configure -state normal
        
        set QWIKMD::inpFile ""
        set QWIKMD::proteinmcr "(not name QWIKMDDELETE and protein)"
        set QWIKMD::nucleicmcr "(not name QWIKMDDELETE and nucleic)"
        set QWIKMD::glycanmcr "(not name QWIKMDDELETE and glycan)"
        set QWIKMD::lipidmcr "(not name QWIKMDDELETE and lipid)"
        set QWIKMD::heteromcr "(not name QWIKMDDELETE and hetero and not qwikmd_protein and not qwikmd_lipid and not qwikmd_nucleic and not qwikmd_glycan and not water)"
        set QWIKMD::maxSteps [list]
        set QWIKMD::atmsNames ""
        set QWIKMD::atmsMol ""
        set QWIKMD::atmsLables ""
        set QWIKMD::atmsDeleteNames [list]
        set QWIKMD::atmsOrigNames ""
        set QWIKMD::atmsOrigIdex ""
        set QWIKMD::atmsOrigElem ""
        set QWIKMD::atmsOrigResid ""
        set QWIKMD::atmsRename [list]
        set QWIKMD::atmsRenameLog [list]
        set QWIKMD::atmsElemLog [list]
        set QWIKMD::atmsDeleteLog [list]
        set QWIKMD::atmsReorderLog [list]
        set QWIKMD::topofilename ""
        set QWIKMD::totcharge 0.00
        if {[info exists QWIKMD::advGui(membrane,center,y)]} {
            unset QWIKMD::advGui(membrane,center,x)
            unset QWIKMD::advGui(membrane,center,y)
            unset QWIKMD::advGui(membrane,center,z)
            unset QWIKMD::advGui(membrane,rotate,x)
            unset QWIKMD::advGui(membrane,rotate,y)
            unset QWIKMD::advGui(membrane,rotate,z)
        }
        set QWIKMD::membranebox [list]
        global env
        set tempLib ""
        # Delete all the temporary files created in the system temp folder
        # such as NAMD configuration files, membrane pdb and psf files
        set listToDelete [list "*.conf" "Renumber_Residues.txt" "membrane.pdb" "membrane.psf" "torplot_temp.pdb" "*.rtf"]
        foreach fileList $listToDelete {
            catch {glob $env(QWIKMDTMPDIR)/$fileList} delFile
            if {[file isfile [lindex ${delFile} 0]] == 1} {
                foreach file $delFile {
                    catch {file delete -force -- ${file}}
                }
            }
        }
    }
    if {$opt >=1} {

        array unset QWIKMD::mutate *
        set QWIKMD::mutindex ""
        array unset QWIKMD::protonate *
        set QWIKMD::protindex ""
        array unset QWIKMD::dorename * 
        set QWIKMD::renameindex ""
        array unset QWIKMD::protres *
        set QWIKMD::patchestr ""
        $QWIKMD::advGui(qmoptions,ptcqmwdgt) delete 1.0 end
        destroy $QWIKMD::selResGui
        if {[winfo exists $QWIKMD::selResGui] == 1} {
            destroy $QWIKMD::messWinGui
        }
        if {$opt > 1} {
            set QWIKMD::selnotbooks [list]
            set QWIKMD::topoerror ""
            set QWIKMD::chirerror ""
            set QWIKMD::cisperror ""
            set QWIKMD::gaps ""
            set QWIKMD::torsionOutlier ""   
            set QWIKMD::torsionMarginal ""  
            set QWIKMD::torsionTotalResidue 0
            array unset QWIKMD::mdProtInfo *
            set QWIKMD::references [list]
            set QWIKMD::refIndex [list]
            if {$QWIKMD::textLogfile != ""} {
                catch {close $QWIKMD::textLogfile}
            }
            set QWIKMD::textLogfile ""
            set QWIKMD::pbcInfo ""
            #set QWIKMD::renumber [list]
            #Populated the advanced protocol tables (MD and SMD)
            set prt {MD SMD "QM/MM"}
            set QWIKMD::prtclSelected -1
            # set numcols [$QWIKMD::advGui(protocoltb,MD) columncount]
            foreach run $prt {
                set QWIKMD::run $run
                QWIKMD::fillPrtcTable
                # set QWIKMD::run $run
                # $QWIKMD::advGui(protocoltb,$QWIKMD::run) delete 0 end
                # set total 4
                # if {$run == "QM/MM"} {
                #     set total 8
                #     $QWIKMD::advGui(qmoptions,ptcqmwdgt) insert 1.0 [format %s "!B3LYP 6-31G* Grid4 PAL8\n!EnGrad TightSCF"]
                #     set QWIKMD::advGui(qmoptions,ptcqmval) {"!B3LYP 6-31G* Grid4 PAL8" "!EnGrad TightSCF"}
                # }
                # for {set i 0} {$i < $total} {incr i} {QWIKMD::addProtocol;
                #     #QWIKMD::checkProc $i
                # }
                # for {set i 0} {$i < $numcols} {incr i} {$QWIKMD::advGui(protocoltb,$QWIKMD::run) columnconfigure $i -editable true}
            }
            
            $QWIKMD::advGui(qmoptions,soft,cmb) configure -state readonly
            $QWIKMD::advGui(qmoptions,stpathbtt) configure -state normal
            $QWIKMD::advGui(qmoptions,lssmode,cmb) configure -state readonly
            $QWIKMD::advGui(qmoptions,ptcharge,cmb) configure -state readonly
            $QWIKMD::advGui(qmoptions,cmptcharge,cmb) configure -state readonly
            $QWIKMD::advGui(qmoptions,switchtype,cmb) configure -state readonly
            $QWIKMD::advGui(qmoptions,ptchrgschm,cmb) configure -state readonly
            $QWIKMD::advGui(qmoptions,ptcqmwdgt) configure -state normal
            set QWIKMD::advGui(qmtable,QMreg) 0
            set QWIKMD::advGui(qmoptions,soft) "ORCA"
            set QWIKMD::advGui(qmoptions,lssmode) "Off"
            set QWIKMD::advGui(qmoptions,ptcharge) On
            set QWIKMD::advGui(qmoptions,cmptcharge) Off
            set QWIKMD::advGui(qmoptions,switchtype) "Switch"
            set QWIKMD::advGui(qmoptions,ptchrgschm) "Round"
            $QWIKMD::advGui(qmoptions,ptcqmwdgt) delete 1.0 end
            $QWIKMD::advGui(qmoptions,ptcqmwdgt) insert 1.0 [format %s "!B3LYP 6-31G* Grid4 PAL[QWIKMD::procs]\n!EnGrad TightSCF"]
            set QWIKMD::advGui(qmoptions,ptcqmval) {"!B3LYP 6-31G* Grid4 PAL[QWIKMD::procs]" "!EnGrad TightSCF"}
            set QWIKMD::advGui(qmoptions,qmgentopo) 0
            set QWIKMD::advGui(qmoptions,ressel) ""
            set QWIKMD::run MD
            
            set val {MD SMD}
            foreach run $val {
                set QWIKMD::basicGui(prtcl,$run,equi) 1
                set QWIKMD::basicGui(prtcl,$run,md) 1
                $QWIKMD::basicGui(prtcl,$run,mdbtt) configure -state normal
                $QWIKMD::basicGui(prtcl,$run,equibtt) configure -state normal
                $QWIKMD::basicGui(prtcl,$run,mdtime) configure -state normal
                $QWIKMD::basicGui(prtcl,$run,mdtemp) configure -state normal
                if {$run == "SMD"} {
                    set QWIKMD::basicGui(prtcl,$run,smd) 1
                    $QWIKMD::basicGui(prtcl,$run,smdbtt) configure -state normal
                    $QWIKMD::basicGui(prtcl,$run,smdlength) configure -state normal
                    $QWIKMD::basicGui(prtcl,$run,smdvel) configure -state normal
                    $QWIKMD::advGui(prtcl,$run,smdlength) configure -state normal
                    $QWIKMD::advGui(prtcl,$run,smdvel) configure -state normal
                }
            }
            set QWIKMD::basicGui(currenttime,0) ""
            set QWIKMD::basicGui(currenttime,1) ""
            set QWIKMD::autorenameLog [list]
            grid conf $QWIKMD::basicGui(currenttime,pgframe) -row 5 -column 0 -pady 2 -sticky nsew
            grid conf $QWIKMD::advGui(currenttime,pgframe) -row 5 -column 0 -pady 2 -sticky nsew
            if {[info exists $QWIKMD::topoPARAMGUI.f1.tableframe.tb]} {
                $QWIKMD::topoPARAMGUI.f1.tableframe.tb delete 0 end
            }
            
            # $QWIKMD::topGui.nbinput.f2.fcontrol.fcolapse.f1.imd.button_Pause configure -state normal
            # $QWIKMD::topGui.nbinput.f2.fcontrol.fcolapse.f1.imd.button_Finish configure -state normal
            # $QWIKMD::topGui.nbinput.f2.fcontrol.fcolapse.f1.imd.button_Detach configure -state normal
            
            set numtabs [llength [$QWIKMD::topGui.nbinput tabs]]
            for {set i 0} {$i < $numtabs} {incr i} {
                $QWIKMD::topGui.nbinput tab $i -state normal
                if {$i < 2} {
                    set note [lindex $QWIKMD::notebooks [expr $i +1]] 
                    set tabs [llength  [$note tabs]]
                    for {set j 0} {$j < $tabs} {incr j} {
                        $note tab $j -state normal
                    }
                    QWIKMD::defaultIMDbtt $i normal
                    [lindex $QWIKMD::livebtt $i] configure -state normal
                    if {$i == 1} {
                        $QWIKMD::advGui(ignoreforces,wdgt) configure -state disabled
                        set QWIKMD::advGui(ignoreforces) 1
                    }
                    [lindex $QWIKMD::preparebtt $i] configure -state normal
                }
            }

            
            
            $QWIKMD::topGui configure -cursor {}; update
            
            set QWIKMD::ParameterList [list] 
            set QWIKMD::TopList [list] 
            set QWIKMD::topoinfo [list]
            set QWIKMD::ParameterList [glob $env(CHARMMPARDIR)/*36*.prm]
            set str [glob $env(CHARMMPARDIR)/*.str]
            
            set QWIKMD::ParameterList [concat $str $QWIKMD::ParameterList]
            
            lappend QWIKMD::TopList [file join $env(CHARMMTOPDIR) top_all36_prot.rtf]
            lappend QWIKMD::TopList [file join $env(CHARMMTOPDIR) top_all36_lipid.rtf]
            lappend QWIKMD::TopList [file join $env(CHARMMTOPDIR) top_all36_na.rtf]
            lappend QWIKMD::TopList [file join $env(CHARMMTOPDIR) top_all36_carb.rtf]
            lappend QWIKMD::TopList [file join $env(CHARMMTOPDIR) top_all36_cgenff.rtf]
            lappend QWIKMD::TopList [file join $env(CHARMMTOPDIR) toppar_all36_carb_glycopeptide.str]
            lappend QWIKMD::TopList [file join $env(CHARMMTOPDIR) toppar_water_ions_namd.str]
            for {set i 0} {$i < [llength $str]} {incr i} {
                if {[lsearch $QWIKMD::TopList [file tail [lindex $str $i]]] == -1} {
                    lappend QWIKMD::TopList [lindex $str $i]
                }
            }
            psfcontext reset
            QWIKMD::reviewTopPar 1
            QWIKMD::loadTopologies

            set index [lsearch -index 0 $QWIKMD::topoinfo "${env(CHARMMTOPDIR)}top_all36_cgenff.rtf"]
            set topo [lindex $QWIKMD::topoinfo $index]
            set reslist [::Toporead::topology_get resnames $topo]
            set listtemp [list]
            foreach residue $reslist {
                if {[string length $residue] <= 4 && \
                    [::Toporead::topology_contains_pres $topo $residue] == -1 &&\
                    [lsearch $QWIKMD::hetero $residue ] == -1} {
                    lappend listtemp $residue
                }
            }
            set listtemp [lsort -unique -dictionary $listtemp]
            set QWIKMD::hetero [concat $QWIKMD::hetero $listtemp]
            set QWIKMD::heteronames [concat $QWIKMD::heteronames $listtemp]
            QWIKMD::changeScheme
            QWIKMD::changeBCK
            display update on 
            update
            
        }

    }

    atomselect macro qwikmd_protein $QWIKMD::proteinmcr
    atomselect macro qwikmd_nucleic $QWIKMD::nucleicmcr
    atomselect macro qwikmd_glycan $QWIKMD::glycanmcr
    atomselect macro qwikmd_lipid $QWIKMD::lipidmcr
    atomselect macro qwikmd_hetero $QWIKMD::heteromcr
    destroy $QWIKMD::advGui(analyze,basic,ntb).volumecalc
    destroy $QWIKMD::advGui(analyze,basic,ntb).pressurecalc
    destroy $QWIKMD::advGui(analyze,basic,ntb).tempcalc
    destroy $QWIKMD::advGui(analyze,basic,ntb).enertotal
    destroy $QWIKMD::advGui(analyze,basic,ntb).enerelect
    destroy $QWIKMD::advGui(analyze,basic,ntb).enerkinetic
    destroy $QWIKMD::advGui(analyze,basic,ntb).enerpoten
    destroy $QWIKMD::advGui(analyze,basic,ntb).enerbond
    destroy $QWIKMD::advGui(analyze,basic,ntb).enerangle
    destroy $QWIKMD::advGui(analyze,basic,ntb).enerdihedral
    destroy $QWIKMD::advGui(analyze,basic,ntb).enervdw
    destroy $QWIKMD::advGui(analyze,basic,ntb).frmsd
    set QWIKMD::resallnametype 1
    set QWIKMD::tabprev -1
    set QWIKMD::tabprevmodf 1
    set QWIKMD::tabprevanaly -1
    set QWIKMD::basicGui(solvent,MD,0) "Implicit"
    set QWIKMD::basicGui(solvent,SMD,0) "Implicit"
    set QWIKMD::advGui(solvent,MD,0) "Explicit"
    set QWIKMD::advGui(solvent,SMD,0) "Explicit"
    set QWIKMD::advGui(solvent,MDFF,0) "Vacuum"
    set QWIKMD::advGui(solvent,QM/MM,0) "Explicit"

    set QWIKMD::advGui(addmol) "10"
    
    set prt {MD SMD "QM/MM"}
    foreach run $prt {
        set QWIKMD::advGui(saltconc,$run,0) "0.15"
        set QWIKMD::advGui(saltions,$run,0) "NaCl"
        set QWIKMD::advGui(solvent,minimalbox,$run) 0
        set QWIKMD::advGui(solvent,boxbuffer,$run) 15
    }

    set prt {MD SMD MDFF}
    foreach run $prt {
        set QWIKMD::basicGui(saltconc,$run,0) "0.15"
        set QWIKMD::basicGui(saltions,$run,0) "NaCl"
        set QWIKMD::basicGui(temperature,$run,0) "27"
    }

    set QWIKMD::basicGui(mdtime,0) "10.0"
    set QWIKMD::basicGui(mdtime,1) 0
    set QWIKMD::basicGui(plength) 10.0
    set QWIKMD::basicGui(pspeed) 2.5
    set QWIKMD::delete ""
    set QWIKMD::rename ""
    array unset QWIKMD::chains *
    array unset QWIKMD::index_cmb *
    array set QWIKMD::index_cmb ""
    set QWIKMD::rmsdGui ""
    set QWIKMD::smdGui ""
    set QWIKMD::hbondsGui ""
    set QWIKMD::plotwindow ""
    set QWIKMD::plotwindowSMD ""
    set QWIKMD::plotwindowHB ""
    set QWIKMD::energyTotGui ""
    set QWIKMD::energyElectGui ""
    set QWIKMD::energyKineGui ""
    set QWIKMD::energyPotGui ""
    
    set QWIKMD::energyBondGui ""
    set QWIKMD::energyAngleGui ""
    set QWIKMD::energyDehidralGui ""
    set QWIKMD::energyVdwGui ""
    set QWIKMD::topMol ""
    set QWIKMD::nmrstep ""
    set QWIKMD::state 0
    set QWIKMD::stop 1 
    set QWIKMD::rmsdsel "all"
    set QWIKMD::timestep 2
    set QWIKMD::imdFreq 10
    set QWIKMD::load 0
    set QWIKMD::lastframe ""
    set QWIKMD::runstep 0
    set QWIKMD::residtbprev ""
    set QWIKMD::resrepname ""
    set QWIKMD::combovalues ""
    set QWIKMD::tablemode "inspection"
    set QWIKMD::selected 1  
    set QWIKMD::buttanchor 0
    array unset QWIKMD::color *
    set QWIKMD::prevRes ""
    set QWIKMD::prevtype ""
    set QWIKMD::timeXrmsd 0
    set QWIKMD::rmsd 0
    set QWIKMD::timeXsmd ""
    set QWIKMD::smdvals ""
    set QWIKMD::smdvalsavg ""
    set QWIKMD::smdfirstdist ""
    set QWIKMD::ts 0
    set QWIKMD::counterts 0
    set QWIKMD::prevcounterts 0
    set QWIKMD::prevcountertsmd 0
    set QWIKMD::countertssmd 0
    set QWIKMD::restts 0
    set QWIKMD::smdxunit "time"
    set QWIKMD::smdcurrentpos 0
    set QWIKMD::smddistance 0
    set QWIKMD::rmsdprevx 0
    set QWIKMD::hbondsprevx 0
    set QWIKMD::timeXhbonds ""
    set QWIKMD::hbonds ""
    set QWIKMD::enertotal 1
    set QWIKMD::enerelect 0
    set QWIKMD::enerpoten 0
    set QWIKMD::enerkinetic 0
    set QWIKMD::enerbond 0
    set QWIKMD::enerangle 0
    set QWIKMD::enerdihedral 0
    set QWIKMD::enervdw 0
    set QWIKMD::calcfreq 20
    set QWIKMD::smdfreq 40
    set QWIKMD::dcdfreq 1000
    set QWIKMD::warnresid 0
    set QWIKMD::prepared 0
    set QWIKMD::hbondssel "intra"
    set QWIKMD::hbondsrepname ""
    set QWIKMD::enecurrentpos 0
    set QWIKMD::eneprevx 0
    set QWIKMD::enecurrentpos 0
    set QWIKMD::enetotval ""
    set QWIKMD::enetotpos ""

    set QWIKMD::enebondval ""
    set QWIKMD::enebondpos ""
    set QWIKMD::eneangleval ""
    set QWIKMD::eneanglepos ""
    set QWIKMD::enedihedralval ""
    set QWIKMD::enedihedralpos ""
    set QWIKMD::enevdwval ""
    set QWIKMD::enevdwpos ""

    set QWIKMD::lastrmsd -1
    set QWIKMD::lasthbond -1
    set QWIKMD::lastsmd -1
    set QWIKMD::lastenetot -1
    set QWIKMD::lastenekin -1
    set QWIKMD::lastenepot -1
    set QWIKMD::lastenebond -1
    set QWIKMD::lasteneangle -1
    set QWIKMD::lastenedihedral -1
    set QWIKMD::lastenevdw -1
    set QWIKMD::enekinval ""
    set QWIKMD::enekinpos ""
    set QWIKMD::eneelectval ""
    set QWIKMD::eneelectpos ""
    set QWIKMD::enepotval ""
    set QWIKMD::enepotpos ""
    set QWIKMD::CondGui ".qwikmdCONGui"
    set QWIKMD::tempGui ""
    set QWIKMD::pressGui ""
    set QWIKMD::volGui ""
    set QWIKMD::plotwindowCON ""
    set QWIKMD::lasttemp -1
    set QWIKMD::lastpress -1
    set QWIKMD::lastvol -1
    set QWIKMD::tempcalc 1
    set QWIKMD::pressurecalc 0
    set QWIKMD::volumecalc 0
    set QWIKMD::condprevx 0
    set QWIKMD::condcurrentpos 0
    set QWIKMD::condprevindex 0
    set QWIKMD::condplotview 0
    set QWIKMD::pressvalavg [list]
    set QWIKMD::volvalavg [list]
    set QWIKMD::tempval ""
    set QWIKMD::temppos ""
    set QWIKMD::pressval ""
    set QWIKMD::presspos ""
    set QWIKMD::volval ""
    set QWIKMD::volpos ""
    set QWIKMD::rmsdplotview 0
    set QWIKMD::hbondsplotview 0
    set QWIKMD::eneplotview 0
    set QWIKMD::condplotview 0
    set QWIKMD::smdplotview 0
    set QWIKMD::smdprevindex 0
    set mollist [molinfo list]
    set QWIKMD::showMdOpt 0
    set QWIKMD::numProcs [QWIKMD::procs]
    set QWIKMD::gpu 1
    set QWIKMD::mdPrec 0
    set QWIKMD::topparmTable ""
    set QWIKMD::topparmTableError 0
    set QWIKMD::rmsfrep ""
    set QWIKMD::sasarep ""
    set QWIKMD::sasarepTotal1 ""
    set QWIKMD::sasarepTotal2 ""
    set QWIKMD::SASAGui ""
    set QWIKMD::CSASAGui ""
    set QWIKMD::rmsfGui ""
    set QWIKMD::SPHGui ""
    set QWIKMD::MBGui ""
    set QWIKMD::qtempGui ""
    set QWIKMD::tempDistGui ""
    set QWIKMD::membranebox [list]
    set QWIKMD::bindTop 0
    set QWIKMD::loadremovewater 0
    set QWIKMD::loadremoveions 0
    set QWIKMD::loadremovehydrogen 0
    set QWIKMD::loadinitialstruct 0
    set QWIKMD::loadstride 1
    set QWIKMD::loadlaststep 0
    set QWIKMD::curframe -1
    set QWIKMD::loadprotlist [list]
    # MDFF protocol frame default values 
    set QWIKMD::advGui(mdff,min) 200
    set QWIKMD::advGui(mdff,mdff) 50000
    $QWIKMD::advGui(protocoltb,MDFF) delete 0 end
    $QWIKMD::advGui(protocoltb,MDFF) insert end {none "same fragment as protein" "same fragment as protein" "same fragment as protein"}
    for {set i 0} {$i < 4} {incr i} {$QWIKMD::advGui(protocoltb,MDFF) columnconfigure $i -editable true}
    set index [expr [llength $QWIKMD::notebooks] -2]
    for {set i $index} {$i < [llength $QWIKMD::notebooks]} {incr i} {
        set tabs [ [lindex $QWIKMD::notebooks $i] tabs ]
        foreach tab $tabs {
            destroy $tab
        }
    }
    set QWIKMD::membraneFrame ""

    for {set i 0} {$i < [llength $mollist]} {incr i} {
        mol delete [lindex $mollist $i]
    }
    set QWIKMD::basicGui(mdtime,1) [expr [expr {$QWIKMD::basicGui(plength) / $QWIKMD::basicGui(pspeed)} *100 ] /100]
    set QWIKMD::advGui(analyze,advance,calcombo) "H Bonds"
    QWIKMD::AdvancedSelected

    
    set prt {MD SMD MDFF "QM/MM"}
    foreach run $prt {
        if {$run != "MDFF" && $run != "QM/MM"} {
            $QWIKMD::basicGui(solvent,$run) configure -state readonly
            $QWIKMD::basicGui(saltions,$run) configure -state readonly
            $QWIKMD::basicGui(saltconc,$run) configure -state normal
        } elseif {$run == "QM/MM"} {
                $QWIKMD::advGui(qmtable) columnconfigure 2 -editable true 
                $QWIKMD::advGui(qmtable) columnconfigure 3 -editable true -editwindow ttk::combobox 
        }
        $QWIKMD::advGui(solvent,$run) configure -state readonly
        $QWIKMD::advGui(saltions,$run) configure -state readonly
        $QWIKMD::advGui(saltconc,$run) configure -state normal
        $QWIKMD::advGui(solvent,boxbuffer,$run,entry) configure -state readonly

    }
    QWIKMD::ChangeSolvent
    if {[info exists QWIKMD::basicGui(shadows)] == 0} {
        set QWIKMD::basicGui(shadows) [display get shadows]
        set QWIKMD::basicGui(ambientocclusion) [display get ambientocclusion]
        set QWIKMD::basicGui(cuedensity) [display get cuedensity]
        set QWIKMD::basicGui(rendermode) [display get rendermode]
    }

}

## fill the current protocol table with the default values
## Since the first .qwikmd files were not deleting the protocol
## tables before add, the procedure has to be also done outside of the reset
## proc (QWIKMD::ChangeMdSmd) 
proc QWIKMD::fillPrtcTable {} {
    #$QWIKMD::advGui(protocoltb,$QWIKMD::run) delete 0 end
    set numcols [$QWIKMD::advGui(protocoltb,$QWIKMD::run) columncount]

    set total 4
    if {$QWIKMD::run == "QM/MM"} {
        $QWIKMD::advGui(qmoptions,ptcqmwdgt) insert 1.0 [format %s "!B3LYP 6-31G* Grid4 PAL8\n!EnGrad TightSCF"]
        set QWIKMD::advGui(qmoptions,ptcqmval) {"!B3LYP 6-31G* Grid4 PAL8" "!EnGrad TightSCF"}
    }
    for {set i 0} {$i < $total} {incr i} {QWIKMD::addProtocol}
    for {set i 0} {$i < $numcols} {incr i} {$QWIKMD::advGui(protocoltb,$QWIKMD::run) columnconfigure $i -editable true}
}

#############################
## Main qwikMD GUI builder###
#############################

proc QWIKMD::path {} {
    global env
    display resetview
    set nameLayer ""
    if {[winfo exists $QWIKMD::topGui] != 1} {
        toplevel $QWIKMD::topGui
    }  

    ttk::style map TCombobox -fieldbackground [list readonly #ffffff]

    grid columnconfigure $QWIKMD::topGui 0 -weight 1
    grid columnconfigure $QWIKMD::topGui 1 -weight 0
    grid rowconfigure $QWIKMD::topGui 0 -weight 0
    grid rowconfigure $QWIKMD::topGui 1 -weight 1
    ## Title of the windows
    wm title $QWIKMD::topGui "QwikMD - Easy and Fast Molecular Dynamics" ;# titulo da pagina

    #wm grid $QWIKMD::topGui 50 95 1 1
    
    grid [ttk::frame $QWIKMD::topGui.f0] -row 0 -column 0 -sticky ew
    grid columnconfigure $QWIKMD::topGui.f0 0 -weight 1
    grid rowconfigure $QWIKMD::topGui.f0 0 -weight 1
    grid rowconfigure $QWIKMD::topGui.f0 1 -weight 1
    grid [ttk::frame $QWIKMD::topGui.f0.info] -row 0 -column 1 -sticky ens

    bind $QWIKMD::topGui <Button-1> {
        if {$QWIKMD::bindTop == 0} {
            wm protocol $QWIKMD::topGui WM_DELETE_WINDOW QWIKMD::closeQwikmd
            set QWIKMD::bindTop 1
        }       
    }
    ###################################################################
    ## Add info usage (QWIKMD::createInfoButton $frame $row $column
    ###################################################################

    QWIKMD::createInfoButton $QWIKMD::topGui.f0.info 0 1

    grid [ttk::button $QWIKMD::topGui.f0.info.help -text "Help..." -padding "2 0 2 0" -command {vmd_open_url [string trimright [vmdinfo www] /]/plugins/qwikmd}] -row 0 -column 0 -sticky ens -padx 2


    grid [ttk::notebook $QWIKMD::topGui.nbinput ] -row 1 -column 0 -sticky news -padx 0

    grid columnconfigure $QWIKMD::topGui.nbinput 0 -weight 1
    grid rowconfigure $QWIKMD::topGui.nbinput 1 -weight 1

    lappend QWIKMD::notebooks "$QWIKMD::topGui.nbinput"

    ttk::frame $QWIKMD::topGui.nbinput.f1
    grid columnconfigure $QWIKMD::topGui.nbinput.f1 0 -weight 1
    grid rowconfigure $QWIKMD::topGui.nbinput.f1 1 -weight 0
    grid rowconfigure $QWIKMD::topGui.nbinput.f1 2 -weight 2

    ttk::frame $QWIKMD::topGui.nbinput.f2
    grid columnconfigure $QWIKMD::topGui.nbinput.f2 0 -weight 1
    grid rowconfigure $QWIKMD::topGui.nbinput.f2 1 -weight 0
    grid rowconfigure $QWIKMD::topGui.nbinput.f2 2 -weight 1
    grid rowconfigure $QWIKMD::topGui.nbinput.f2 3 -weight 0
    grid rowconfigure $QWIKMD::topGui.nbinput.f2 4 -weight 0
    grid rowconfigure $QWIKMD::topGui.nbinput.f2 5 -weight 1

    ttk::frame $QWIKMD::topGui.nbinput.f3
    grid columnconfigure $QWIKMD::topGui.nbinput.f3 0 -weight 1
    grid rowconfigure $QWIKMD::topGui.nbinput.f3 0 -weight 1


    ttk::frame $QWIKMD::topGui.nbinput.f4
    grid columnconfigure $QWIKMD::topGui.nbinput.f4 0 -weight 1
    grid rowconfigure $QWIKMD::topGui.nbinput.f4 0 -weight 1


    $QWIKMD::topGui.nbinput add $QWIKMD::topGui.nbinput.f1 -text "Easy Run" -sticky news 
    $QWIKMD::topGui.nbinput add $QWIKMD::topGui.nbinput.f2 -text "Advanced Run"  -sticky news
 
    $QWIKMD::topGui.nbinput add $QWIKMD::topGui.nbinput.f3 -text "Basic Analysis" -sticky news
    $QWIKMD::topGui.nbinput add $QWIKMD::topGui.nbinput.f4 -text "Advanced Analysis"  -sticky news

    ##################################################################################
    ## Change the content of the info button to display when Run or analysis tab is selected 
    ##################################################################################
    
    QWIKMD::BuildRun $QWIKMD::topGui.nbinput.f1 basic
    QWIKMD::BuildRun $QWIKMD::topGui.nbinput.f2 advanced

    QWIKMD::BasicAnalyzeFrame $QWIKMD::topGui.nbinput.f3
    QWIKMD::AdvancedAnalyzeFrame $QWIKMD::topGui.nbinput.f4
    bind $QWIKMD::topGui.nbinput <<NotebookTabChanged>> QWIKMD::changeMainTab
}

##################################################################################
## proc to kill IMD simulation currently running
##################################################################################
proc QWIKMD::checkIMD {} {
    set returnval 2
    set tabid [$QWIKMD::topGui.nbinput index current]
    if {$QWIKMD::basicGui(live,$tabid) == 1 && $QWIKMD::prepared == 1 && [[lindex $QWIKMD::runbtt [$QWIKMD::topGui.nbinput index current]] cget -state] == "disabled"} {
        set answer [tk_messageBox -message "QwikMD will terminate any active simulation. Do you want to continue?"\
         -title "Running Simulation" -icon warning -type yesno -parent $QWIKMD::topGui]
        if {$answer == "yes"} {
            QWIKMD::killIMD
            set returnval 1
        } else {
            set returnval 0
        }
    }
    return $returnval
}
##################################################################################
## proc to be executed before closing QwikMD window
##################################################################################
proc QWIKMD::closeQwikmd {} {
    if {[QWIKMD::checkIMD] == 0} {
        return
    } 
    set QWIKMD::prepared 0
    set tabid [$QWIKMD::topGui.nbinput index current]
    if {$tabid > 1} {
        $QWIKMD::topGui.nbinput select 0
    }
    set QWIKMD::basicGui(live,$tabid) 0
    QWIKMD::resetBtt 2
    set QWIKMD::bindTop 0
    wm withdraw $QWIKMD::topGui
    
}
############################################################################################
## proc triggered when the tabs of main notebook are selected (Easy Run, Advanced Run, ...)
#############################################################################################
proc QWIKMD::changeMainTab {} {

    ## return to the same tab as the loaded *.qwikmd was generated
    proc returnToTabid {} {
        set axuvar [expr $QWIKMD::tabprevanaly -1]
        set QWIKMD::tabprevanaly -1
        set QWIKMD::tabprevmodf [expr [$QWIKMD::topGui.nbinput index current] +1]
        $QWIKMD::topGui.nbinput select $axuvar
    }
    ## change the top info button content to analysis text if one of analysis tab is selected
    if {[$QWIKMD::topGui.nbinput index current] == 2 || [$QWIKMD::topGui.nbinput index current] == 3} {
        bind $QWIKMD::topGui.f0.info.info <Button-1> {
            set val [QWIKMD::analyInfo]
            set QWIKMD::link [lindex $val 1]
            QWIKMD::infoWindow analyInfo [lindex $val 0] [lindex $val 2]
        }
    } else {
        ## change the top info button content to MD intro text if one of run tab is selected
        bind $QWIKMD::topGui.f0.info.info <Button-1> {
            set val [QWIKMD::introInfo]
            set QWIKMD::link [lindex $val 1]
            QWIKMD::infoWindow introInfo [lindex $val 0] [lindex $val 2]                
        }
        ## hide membrane, edit atom, and atom selection widgets from the Structure Windows when not needed 
        if {([info exists QWIKMD::advGui(membrane,frame)] == 1 || [info exists QWIKMD::advGui(atmsel,frame)] == 1)  && [winfo exists $QWIKMD::selResGui] == 1 && [wm title $QWIKMD::selResGui] == "Structure Manipulation/Check"} {       
            if {[$QWIKMD::topGui.nbinput index current] == 0 || $QWIKMD::prepared == 1 || $QWIKMD::load == 1} {
                if {[winfo exists $QWIKMD::advGui(membrane,frame)]} {
                    grid forget $QWIKMD::advGui(membrane,frame)
                    grid forget $QWIKMD::selresPatcheFrame
                }
                if {[winfo exists $QWIKMD::advGui(atmsel,frame)] && [$QWIKMD::topGui.nbinput index current] == 0} {
                    grid forget $QWIKMD::advGui(atmsel,frame)
                }
            } elseif {$QWIKMD::prepared == 0 && $QWIKMD::load == 0 && [$QWIKMD::topGui.nbinput index current] == 1} {
                grid conf $QWIKMD::advGui(membrane,frame) -row 4 -column 0 -sticky nwe -padx 2 -pady 2
                grid conf $QWIKMD::advGui(atmsel,frame) -row 1 -column 0 -sticky nwe -padx 4
                grid conf $QWIKMD::selresPatcheFrame -row 1 -column 0 -sticky nswe -pady 2
            }
        }
    }
    set tabid [expr [$QWIKMD::topGui.nbinput index current] +1]

    if {$QWIKMD::tabprev == -1} {
        set QWIKMD::tabprev 1
        set QWIKMD::tabprevmodf 1
    }
    ## Sync the content of the main table between advance <-> easy run tabs 
    if {$tabid <= 2 && $QWIKMD::tabprevmodf != $tabid} {
        QWIKMD::ChangeMdSmd $tabid
        $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb configure -state normal

        $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb delete 0 end
        
        set lines [$QWIKMD::topGui.nbinput.f$QWIKMD::tabprevmodf.tableframe.tb get 0 end]
        for {set i 0} {$i < [llength $lines]} {incr i} {
            $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb insert end [lindex $lines $i]
        }
        
        $QWIKMD::topGui.nbinput.f$QWIKMD::tabprevmodf.tableframe.tb delete 0 end
        $QWIKMD::topGui.nbinput.f$QWIKMD::tabprevmodf.tableframe.tb configure -state disabled
        
        set QWIKMD::tabprevmodf $tabid
        #QWIKMD::ChangeSolvent
    }
    set QWIKMD::tabprev $tabid

    set runtab [lindex [lindex $QWIKMD::selnotbooks 0] 1]
    set prtctab [lindex [lindex $QWIKMD::selnotbooks 1] 1]
    set tablist {MD SMD MDFF QM/MM}
    ## only when *.qwikmd file was loaded. If the tab currently selected is not the one saved in
    ## *.qwikmd, select the saved tab  
    if {$QWIKMD::tabprevanaly != -1 && $runtab == [expr $QWIKMD::tabprevmodf -1] && \
        $QWIKMD::run == [lindex $tablist $prtctab] && $tabid <= 2} {
            returnToTabid
            return
    }
    ### check if the run tab selected before selecting the 
    ### analysis tab is the one prepared/loaded
    if {$tabid > 2 && $QWIKMD::load == 1} {        
        set changed 0

        if {$runtab != [expr $QWIKMD::tabprevmodf -1] \
            && $QWIKMD::tabprevanaly == -1} {
            set QWIKMD::tabprevanaly $tabid
            $QWIKMD::topGui.nbinput select $runtab
            update
        }
        if {$QWIKMD::run != [lindex $tablist $prtctab] } {
            if {$QWIKMD::tabprevanaly == -1} {
                set QWIKMD::tabprevanaly $tabid
            }
            if {[$QWIKMD::topGui.nbinput index current] != $runtab} {
                $QWIKMD::topGui.nbinput select $runtab
                update
            }
            [lindex [lindex $QWIKMD::selnotbooks 1] 0] select $prtctab
            update
            returnToTabid
        }

    }
    
}
######################
## Build the Run Tabs
######################
proc QWIKMD::BuildRun {frame level} {
    set gridrow 0
    grid [ttk::frame $frame.fbtload] -row $gridrow -column 0 -sticky ewns -padx 2 -pady 2
    grid columnconfigure $frame.fbtload 1 -weight 1
    
    grid [ttk::button $frame.fbtload.btBrowser -text "Browser" -padding "2 0 2 0" -command {QWIKMD::BrowserButt}] -row 0 -column 0 -sticky w -padx 2

    QWIKMD::balloon $frame.fbtload.btBrowser [QWIKMD::pdbBrowserBL]
    ttk::style configure PdbEntrey.TEntry -foreground $QWIKMD::tempEntry
    grid [ttk::entry  $frame.fbtload.entLoad -textvariable QWIKMD::inputstrct -style PdbEntrey.TEntry -validate focus -validatecommand {
        if {[%W get] == "PDB ID"} {
            %W delete 0 end
            ttk::style configure PdbEntrey.TEntry -foreground black
        } elseif {[%W get] == ""} {
            ttk::style configure PdbEntrey.TEntry -foreground $QWIKMD::tempEntry
            set QWIKMD::inputstrct "PDB ID"
        }
        return 1
        }] -row 0 -column 1 -sticky we
    set QWIKMD::inputstrct "PDB ID"
    QWIKMD::balloon $frame.fbtload.entLoad [QWIKMD::pdbentryLoadBL]
    lappend QWIKMD::loadpdb $frame.fbtload.btLoad
    grid [ttk::button  $frame.fbtload.btLoad -text "Load" -padding "2 0 2 0" -command {
        global env
        if {$QWIKMD::inputstrct != "" && $QWIKMD::inputstrct != "PDB ID"} {
            set file $QWIKMD::inputstrct
            set tab [$QWIKMD::topGui.nbinput index current]
            if {[QWIKMD::resetBtt 2] == 1} {
                return
            }
            $QWIKMD::topGui.nbinput select $tab
            display update off
            $QWIKMD::topGui configure -cursor watch; update 
            
            ## Disable all the tabs when loading the pdb
            ## to avoid the user selecting a different tab
            set numtabs [llength [$QWIKMD::topGui.nbinput tabs]]
            for {set i 0} {$i < $numtabs} {incr i} {
                if {$tab != $i} {
                    $QWIKMD::topGui.nbinput tab $i -state disabled
                }
            }
    
            set QWIKMD::inputstrct $file
            ttk::style configure PdbEntrey.TEntry -foreground black
            QWIKMD::LoadButt $QWIKMD::inputstrct
            if {$QWIKMD::autorename == 1} {
                QWIKMD::applyDeafultPdbalias
            }
            #Check for residues with multiple insertion codes and renumber them sequentially
            set selchain [atomselect $QWIKMD::topMol "all and not water and not ions"]

            ## Check for residues out of order within the same chain (insertion entry in pdb)
            set chainList [$selchain get chain]
            set chainList [lsort -unique $chainList]
            $selchain delete
            set renumber [list]
            foreach chain $chainList {
                set sel [atomselect $QWIKMD::topMol "chain \"$chain\""]
                set insertion [$sel get insertion]
                set listsort [lsort -unique $insertion]
                if {$listsort != "{ }" && [llength $listsort] > 1} {
                    # set resids [lsort -unique -integer [$sel get resid]]
                    set prevres ""
                    set txtini ""
                    set res [list]
                    set newresid [list]
                    set previnsert ""
                    set minres ""
                    set prevfrag ""
                    
                    foreach residaux [$sel get resid] insert [$sel get insertion] frag [$sel get fragment] {
                        set txt "$residaux $insert"
                        if {$minres == ""} {
                            set minres $residaux
                            set prevfrag $frag
                        }
                        if {$txt != $txtini} {
                            lappend res [atomselect $QWIKMD::topMol "chain \"$chain\" and resid \"$residaux\" and insertion \"$insert\" "]
                            if {$prevres != ""} {
                                set increment [expr $residaux - $prevres]
                                if {$increment == 0} {
                                    set increment 1
                                }
                                
                                if {$prevfrag != $frag && $increment == 1} {
                                    #set selaux [atomselect $QWIKMD::topMol "(within 2.0 of (chain \"$chain\" and resid \"$prevres\" and insertion \"$previnsert\")) and (chain \"$chain\" and resid \"$residaux\" and insertion \"$insert\")"]
                                    set increment 2
                                    #$selaux delete
                                }
                                set newresidaux [expr $increment + [lindex $newresid end]]
                                lappend renumber [list ${residaux}_${chain}_$insert ${newresidaux}_$chain]
                                lappend newresid $newresidaux
                            } else {
                                lappend newresid $minres
                            }
                            set txtini $txt
                            set prevres $residaux
                            set previnsert $insert
                            set prevfrag $frag
                        }   
                    }
                    set i 0
                    foreach selaux $res {
                        if {$i != 0} {
                            $selaux set resid [lindex $newresid $i]
                        }
                        $selaux delete
                        incr i
                    }

                }
                $sel delete 
            }
            update

            ## Update the molecule types definition listed in the Structure Manipulation window
            QWIKMD::UpdateMolTypes $QWIKMD::tabprevmodf

            ## Run the Structure check proc that calls strctcheck plugin
            QWIKMD::checkStructur init

            ## Generate the pdb with the residues order corrected and the correspondence 
            ## between the initial numbering and new numbering saved to a text file Renumber_Residues.txt
            ## Initially save the file in the temp folder, then in the saved output folder 
            if {[llength $renumber] > 0} {
                set renumbfile [open "$env(QWIKMDTMPDIR)/Renumber_Residues.txt" w+]
                set w1 14
                set w2 9
                set w3 15
                set sep +-[string repeat - $w1]-+-[string repeat - $w2]-+-[string repeat - $w3]-+-[string repeat - $w1]-+-[string repeat - $w2]-+
                puts $renumbfile $sep
                puts $renumbfile [format "| %*s | %*s | %*s | %*s | %*s |" $w1 "Init Resid" $w2 "Chain" $w3 "Insert Code" $w1 "New Resid" $w2 "Chain"]
                puts $renumbfile $sep
                set chains ""
                foreach txt $renumber {
                    set initresid [split [lindex $txt 0] "_"]
                    set insert [lindex $initresid 2]
                    set finalresid [split [lindex $txt 1] "_"]
                    puts $renumbfile [format "| %*s | %*s | %*s | %*s | %*s |" $w1 "[lindex $initresid 0]" $w2 "[lindex $initresid 1]" $w3 "$insert" $w1 "[lindex $finalresid 0]" $w2 "[lindex $finalresid 1]"]
                    if {[string first [lindex $initresid 1] $chains] == -1} {
                        append chains "[lindex $initresid 1] "
                    }
                }
                puts $renumbfile $sep
                close $renumbfile
                tk_messageBox -message "One or more different insertion codes were found for the chain(s): $chains.\n\
                The renumbering table will be shown after press \"OK\" and will be saved in the working directory after \
                preparation as \"Renumber_Residues.txt\"." -icon warning -title "Residues Renumbering" -type ok -parent $QWIKMD::topGui
                set instancehandle [multitext]
                $instancehandle openfile "$env(QWIKMDTMPDIR)/Renumber_Residues.txt"
            }
            for {set i 0} {$i < $numtabs} {incr i} {
                if {$tab != $i} {
                    $QWIKMD::topGui.nbinput tab $i -state normal
                }
            }
            $QWIKMD::topGui configure -cursor {}; update
            QWIKMD::changeBCK
            display update on
            update
        }
        
    }] -row 0 -column 2 -sticky w -padx 2

    QWIKMD::balloon $frame.fbtload.btLoad [QWIKMD::pdbLoadBL]

    grid [ttk::checkbutton $frame.fbtload.autorename -text "Automatic Residue & Atom Renaming" -variable QWIKMD::autorename] -row 1 -column 1 -sticky ew -padx 2
    set QWIKMD::autorename 1
    lappend QWIKMD::autorenamebtt $frame.fbtload.autorename
    #Selection frame
    incr gridrow
    grid [ttk::frame $frame.selframe] -row $gridrow -column 0 -sticky nwe
    grid columnconfigure $frame.selframe 0 -weight 1
    grid columnconfigure $frame.selframe 1 -weight 1
    grid columnconfigure $frame.selframe 2 -weight 1
    
    ttk::menubutton $frame.selframe.mNMR -text "NMR State" -menu $frame.selframe.mNMR.nmr
    ttk::menubutton $frame.selframe.mCHAIN -text "Chain/Type Selection" -menu $frame.selframe.mCHAIN.chain
    
    if {$level == "basic"} {
        menu $frame.selframe.mNMR.nmr -tearoff 0
        menu $frame.selframe.mCHAIN.chain -tearoff 0
    } else {
        $QWIKMD::topGui.nbinput.f1.selframe.mNMR.nmr clone $frame.selframe.mNMR.nmr
        $QWIKMD::topGui.nbinput.f1.selframe.mCHAIN.chain clone $frame.selframe.mCHAIN.chain
    }
    grid $frame.selframe.mNMR -row 0 -column 0 -sticky nwe -pady 4
    grid $frame.selframe.mCHAIN -row 0 -column 1 -sticky nwe -pady 4

    lappend QWIKMD::nmrMenu $frame.selframe.mNMR
    lappend QWIKMD::chainMenu $frame.selframe.mCHAIN

    grid [ttk::button $frame.selframe.mRESID -text "Structure Manipulation" -command {
        QWIKMD::callStrctManipulationWindow
        wm title $QWIKMD::selResGui "Structure Manipulation\/Check" 
        if {$QWIKMD::prepared != 1 && $QWIKMD::load != 1} {
            QWIKMD::lockSelResid 1
        } else {
            QWIKMD::lockSelResid 0
        }

    } ]  -row 0 -column 2 -sticky nwe -pady 4

    QWIKMD::balloon $frame.selframe.mNMR [QWIKMD::nmrBL]
    QWIKMD::balloon $frame.selframe.mCHAIN [QWIKMD::addChainBL]
    QWIKMD::balloon $frame.selframe.mRESID [QWIKMD::selResidBL]

    QWIKMD::createInfoButton $frame.selframe 0 4
    bind $frame.selframe.info <Button-1> {
        set val [QWIKMD::selectInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow info [lindex $val 0] [lindex $val 2]
    }
    incr gridrow
    ## QwikMD Main Table
    grid [ttk::frame $frame.tableframe] -row $gridrow -column 0 -sticky nwse -padx 4

    grid columnconfigure $frame.tableframe 0 -weight 1
    grid rowconfigure $frame.tableframe 0 -weight 1
    set fro2 $frame.tableframe
    option add *Tablelist.       frame
    option add *Tablelist.background        gray98
    option add *Tablelist.stripeBackground  #e0e8f0
    option add *Tablelist.setGrid           no
    option add *Tablelist.movableColumns    no


        tablelist::tablelist $fro2.tb \
        -columns { 0 "Chain"     center
                0 "Residue Range"    center
                0 "Type" center
                0 "Representation" center
                0 "Color" center 
                } -yscrollcommand [list $fro2.scr1 set] -xscrollcommand [list $fro2.scr2 set] -showseparators 0 -labelrelief groove  -labelbd 1 -selectbackground white \
                -selectforeground black -foreground black -background white -state normal -selectmode single -stretch "all" -stripebackgroun white -height 5\
                -editstartcommand {QWIKMD::mainTableCombosStart 1} -editendcommand QWIKMD::mainTableCombosEnd -forceeditendcommand true

    $fro2.tb columnconfigure 0 -width 0 -sortmode dictionary -name Chain
    $fro2.tb columnconfigure 1 -width 0 -sortmode dictionary -name Range
    $fro2.tb columnconfigure 2 -width 0 -sortmode dictionary -name type
    $fro2.tb columnconfigure 3 -width 0 -sortmode dictionary -name Representation -editable true -editwindow ttk::combobox
    $fro2.tb columnconfigure 4 -width 0 -sortmode dictionary -name Color -editable true -editwindow ttk::combobox


    grid $fro2.tb -row 0 -column 0 -sticky news
    grid columnconfigure $fro2.tb 0 -weight 1; grid rowconfigure $fro2.tb 0 -weight 1

    ##Scrool_BAr V
    scrollbar $fro2.scr1 -orient vertical -command [list $fro2.tb  yview]
     grid $fro2.scr1 -row 0 -column 1  -sticky ens

    ## Scrool_Bar H
    scrollbar $fro2.scr2 -orient horizontal -command [list $fro2.tb xview]
    grid $fro2.scr2 -row 1 -column 0 -sticky swe

    bind [$fro2.tb labeltag] <Any-Enter> {
        set col [tablelist::getTablelistColumn %W]
        set help 0
        switch $col {
            0 {
                set help [QWIKMD::selTabelChainBL]
            }
            1 {
                set help [QWIKMD::selTabelResidBL]
            }
            2 {
                set help [QWIKMD::selTabelTypeBL]
            }
            3 {
                set help [QWIKMD::selTabelRepBL]
            }
            4 {
                set help [QWIKMD::selTabelColorBL]
            }
            default {
                set help $col
            }
        }
        after 1000 [list QWIKMD::balloon:show %W $help]
  
    }
    bind [$fro2.tb labeltag] <Any-Leave> "destroy %W.balloon"
    
    $fro2.tb configure -state disabled
    
    incr gridrow
    grid [ttk::frame $frame.changeBack] -row $gridrow -column 0 -pady 2 -padx 2 -sticky we

    grid columnconfigure $frame.changeBack 0 -weight 1
    grid columnconfigure $frame.changeBack 1 -weight 1
    grid columnconfigure $frame.changeBack 2 -weight 1
    grid columnconfigure $frame.changeBack 3 -weight 1
    grid columnconfigure $frame.changeBack 4 -weight 1
    grid columnconfigure $frame.changeBack 5 -weight 1
    grid [ttk::label $frame.changeBack.lbcheck -text "Background"] -row 0 -column 0 -padx 1 -sticky w

    grid [ttk::radiobutton $frame.changeBack.checkBlack -text "Black" -variable QWIKMD::basicGui(desktop) -value "black" -command QWIKMD::changeBCK] -row 0 -column 1 -padx 1 -sticky w
    grid [ttk::radiobutton $frame.changeBack.checkWhite -text "White" -variable QWIKMD::basicGui(desktop) -value "white" -command QWIKMD::changeBCK] -row 0 -column 2 -padx 1 -sticky w
    grid [ttk::radiobutton $frame.changeBack.checkGradient -text "Gradient" -variable QWIKMD::basicGui(desktop) -value "gradient" -command QWIKMD::changeBCK] -row 0 -column 3 -padx 1 -sticky w

    set QWIKMD::basicGui(desktop) ""
    QWIKMD::balloon $frame.changeBack.checkBlack [QWIKMD::cbckgBlack]
    QWIKMD::balloon $frame.changeBack.checkWhite [QWIKMD::cbckgWhite]
    QWIKMD::balloon $frame.changeBack.checkGradient [QWIKMD::cbckgGradient]

    grid [ttk::label $frame.changeBack.lscheme -text "Color Scheme:"] -row 0 -column 4 -padx 2
    set val {"VMD Classic" "Neutral" "QwikMD" "80s" "Pastel"}
    grid [ttk::combobox $frame.changeBack.comboscheme -values $val -width 13 -justify left -state readonly -textvariable QWIKMD::basicGui(scheme)] -row 0 -column 5 -padx 2 -sticky w
    set QWIKMD::basicGui(scheme) "VMD Classic"

    QWIKMD::balloon $frame.changeBack.comboscheme [QWIKMD::colorScheme]
    bind $frame.changeBack.comboscheme <<ComboboxSelected>> {
        QWIKMD::changeScheme
        %W selection clear
    }
    incr gridrow
    grid rowconfigure $frame $gridrow -weight 0
    grid [ttk::frame $frame.render] -row $gridrow -column 0 -sticky nsew -pady 0 -padx 2 
    grid columnconfigure $frame.render 2 -weight 1

    QWIKMD::RenderFrame $frame.render

    ## Protocol NoteBook
    incr gridrow
    grid [ttk::notebook $frame.nb -padding "1 8 1 1"] -row $gridrow -column 0 -sticky news -padx 0
    lappend QWIKMD::notebooks "$frame.nb"
    grid columnconfigure $frame.nb 0 -weight 1
    if {$level == "basic"} {
        
        ttk::frame $frame.nb.f1
        grid columnconfigure $frame.nb.f1 0 -weight 1
        grid rowconfigure $frame.nb.f1 0 -weight 1
        ttk::frame $frame.nb.f2
        grid columnconfigure $frame.nb.f2 0 -weight 1
        grid rowconfigure $frame.nb.f2 0 -weight 1

        $frame.nb add $frame.nb.f1 -text "Molecular Dynamics" -sticky new
        $frame.nb add $frame.nb.f2 -text "Steered Molecular Dynamics"  -sticky new
        
        ## Frame MD
        QWIKMD::system $frame.nb.f1 $level "MD"
        QWIKMD::protocolBasic $frame.nb.f1 "MD"

        
        #Frame SM

        #QWIKMD::notebook 
        QWIKMD::system $frame.nb.f2 $level "SMD"
        QWIKMD::protocolBasic $frame.nb.f2 "SMD"

        ##############################################
        ## hide MD options in the Run tab by default
        ##############################################
        bind $frame.nb <<NotebookTabChanged>> {QWIKMD::ChangeMdSmd [expr [$QWIKMD::topGui.nbinput index current] +1] }
        

    } else {
        set tab 1

        ## Notebook tab for MD
        ttk::frame $frame.nb.f$tab
        grid columnconfigure $frame.nb.f$tab 0 -weight 1
        grid rowconfigure $frame.nb.f$tab 0 -weight 0
        grid rowconfigure $frame.nb.f$tab 1 -weight 1
        $frame.nb add $frame.nb.f$tab -text "MD" -sticky news

        QWIKMD::system $frame.nb.f$tab $level "MD"
        QWIKMD::protocolAdvanced $frame.nb.f$tab "MD"

        ## Notebook tab for SMD
        incr tab
        ttk::frame $frame.nb.f$tab
        grid columnconfigure $frame.nb.f$tab 0 -weight 1
        grid rowconfigure $frame.nb.f$tab 0 -weight 0
        grid rowconfigure $frame.nb.f$tab 1 -weight 1
        $frame.nb add $frame.nb.f$tab -text "SMD"  -sticky news

        QWIKMD::system $frame.nb.f$tab $level "SMD"
        QWIKMD::protocolAdvanced $frame.nb.f$tab "SMD"
        
        ## Notebook tab for MDFF
        incr tab
        ttk::frame $frame.nb.f$tab
        grid columnconfigure $frame.nb.f$tab 0 -weight 1
        grid rowconfigure $frame.nb.f$tab 0 -weight 0
        grid rowconfigure $frame.nb.f$tab 1 -weight 1
        $frame.nb add $frame.nb.f$tab -text "MDFF" -sticky news

        QWIKMD::system $frame.nb.f$tab $level "MDFF"
        ## MDFF tab is located in the advanced run tab,
        ## but its structure has more in common with the basic run tab
        QWIKMD::protocolBasic $frame.nb.f$tab "MDFF"

        ## Notebook tab for QM/MM
        incr tab
        ttk::frame $frame.nb.f$tab
        grid columnconfigure $frame.nb.f$tab 0 -weight 1
        grid rowconfigure $frame.nb.f$tab 0 -weight 0
        grid rowconfigure $frame.nb.f$tab 1 -weight 1
        $frame.nb add $frame.nb.f$tab -text "QM/MM"  -sticky news

        QWIKMD::system $frame.nb.f$tab $level "QM/MM"
        QWIKMD::protocolAdvanced $frame.nb.f$tab "QM/MM"

        ##############################################
        ## hide MD options in the Run tab by default
        ##############################################
        bind $frame.nb <<NotebookTabChanged>> {QWIKMD::ChangeMdSmd [expr [$QWIKMD::topGui.nbinput index current] +1]}
        
    }
    
    ## Simulation Setup
    incr gridrow
    grid [ttk::frame $frame.fb] -row $gridrow -column 0 -sticky news -pady 2
    grid columnconfigure $frame.fb 0 -weight 1
    grid rowconfigure $frame.fb 0 -weight 0
    grid rowconfigure $frame.fb 1 -weight 0
    grid rowconfigure $frame.fb 1 -weight 1

    grid [ttk::label $frame.fb.prt -text "$QWIKMD::downPoint Simulation Setup"] -row 0 -column 0 -sticky w -pady 1
    #QWIKMD::ChangeSolvent
    bind $frame.fb.prt <Button-1> {
        QWIKMD::hideFrame %W [lindex [grid info %W] 1] "Simulation Setup"
    }
    
    grid [ttk::frame $frame.fb.fcolapse] -row 1 -column 0 -sticky nsew -pady 5
    grid columnconfigure $frame.fb.fcolapse 0 -weight 1

    QWIKMD::createInfoButton $frame.fb 0 0
    bind $frame.fb.info <Button-1> {
        set val [QWIKMD::outputBrowserinfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow outputBrowserinfo [lindex $val 0] [lindex $val 2]
    }

    set framecolapse $frame.fb.fcolapse

    grid [ttk::frame $framecolapse.sep ] -row 1 -column 0 -sticky ew
    grid columnconfigure $framecolapse.sep 0 -weight 1
    grid [ttk::separator $framecolapse.spt -orient horizontal] -row 0 -column 0 -sticky ew -pady 0

    grid [ttk::frame $framecolapse.f1] -row 1 -column 0 -padx 2 -sticky ew
    grid columnconfigure $framecolapse.f1 0 -weight 1



    set framesetup $framecolapse.f1

    grid [ttk::frame $framesetup.fwork] -row 0 -column 0 -pady 5 -padx 2 -sticky nsew
    grid columnconfigure $framesetup.fwork 0 -weight 1
    ttk::style configure WorkDir.TEntry -foreground $QWIKMD::tempEntry
    grid [ttk::entry $framesetup.fwork.outentrey -textvariable QWIKMD::basicGui(workdir,0) -style WorkDir.TEntry -validate focus -validatecommand {
        if {[%W get] == "Working Directory"} {
            %W delete 0 end
            ttk::style configure WorkDir.TEntry -foreground black
        } elseif {[%W get] == ""} {
            ttk::style configure WorkDir.TEntry -foreground $QWIKMD::tempEntry
            set QWIKMD::basicGui(workdir,0) "Working Directory"
        }
        return 1
        }] -row 0 -column 0 -sticky ew -padx 2

    set QWIKMD::basicGui(workdir,0) "Working Directory"
    if {$level == "basic"} {
        set QWIKMD::basicGui(workdir,1) $framesetup.fwork.outentrey
    } else {
        set QWIKMD::basicGui(workdir,2) $framesetup.fwork.outentrey
    }
    
    lappend QWIKMD::loadqwikmd $framesetup.fwork.outload
    grid [ttk::button $framesetup.fwork.outload -text "Load" -command {
            global env
            set extension ".qwikmd"
            set types {
                {{QwikMD}       {".qwikmd"}        }
                {{All}       {"*"}        }
            }
            set fil ""
            set fil [tk_getOpenFile -title "Open InputFile" -filetypes $types -defaultextension $extension]
            if {$fil != ""} {
                display update off
                QWIKMD::resetBtt 1
                set QWIKMD::basicGui(workdir,0) ${fil}

                ## Make compatible with vmd1.9.3b1 versions input file by 
                ## removing the path of the widgets 
                set file [open $QWIKMD::basicGui(workdir,0) r]
                set lines [split [read $file] "\n"]
                close $file
                if {[lindex $lines [expr [llength $lines] -2 ] ]== "QWIKMD::SelResid"} {
                    file copy -force $QWIKMD::basicGui(workdir,0) $QWIKMD::basicGui(workdir,0)_bkup
                    set i 2
                    while {$i < [llength $lines]} {
                        if {[string range [lindex $lines $i] 0 25] == "array set QWIKMD::basicGui" || [string range [lindex $lines $i] 0 23] == "array set QWIKMD::advGui"} {
                            set values [lindex [lindex $lines $i] 3 ]
                            set valuesAux "\{"
                            for {set j 1} {$j < [llength $values]} {incr j 2} {
                                set find [regexp {.qwikmd*} [join [lindex $values $j]]]
                                if {$find == 0 } {
                                    append valuesAux " [lrange $values [expr $j -1] $j]"
                                }
                            }
                            
                            if {[string range [lindex $lines $i] 0 25] == "array set QWIKMD::basicGui"} {
                                lset lines $i "[string range [lindex $lines $i] 0 25] $valuesAux\}"
                            } else {
                                lset lines $i "[string range [lindex $lines $i] 0 23] $valuesAux\}"
                                
                            }

                        }
                        if {[string range [lindex $lines $i] 0 6] == "set aux"} {
                            lset lines $i "set aux \"\[file rootname $QWIKMD::basicGui(workdir,0)\]\""
                        }
                        if {[string range [lindex $lines $i] 0 18] == "QWIKMD::ChangeMdSmd"} {
                            lset lines $i "#[lindex $lines $i]"
                        }
                        if {[string range [lindex $lines $i] 0 19] == "set QWIKMD::confFile"} {
                            lappend lines "set QWIKMD::prevconfFile [string range [lindex $lines $i] 20 end]"
                        }
                        if {[string trimleft [string range [lindex $lines $i] 0 12]] == "mol addfile"} {
                            lset lines $i "#[lindex $lines $i]"
                        }
                        incr i
                    }
                    lset lines [expr [llength $lines] -3] "#[lindex $lines [expr [llength $lines] -3]]"
                    lset lines [expr [llength $lines] -4] "#[lindex $lines [expr [llength $lines] -4]]"
                    lset lines [expr [llength $lines] -5] "#[lindex $lines [expr [llength $lines] -5]]"
                    set file [open $QWIKMD::basicGui(workdir,0) w+]
                    foreach line $lines {
                        puts $file $line
                    }
                    
                    close $file
                }
                set tabid [$QWIKMD::topGui.nbinput index current]
                if {[winfo exists $QWIKMD::selResGui] != 1} {
                    QWIKMD::SelResid
                }
                source $QWIKMD::basicGui(workdir,0)
                ## Moving from single variable controlling the "Live simulation" button
                ## to two (compatible issues with previous versions)
                if {[info exist QWIKMD::basicGui(live)] == 1} {
                    set QWIKMD::basicGui(live,$tabid) $QWIKMD::basicGui(live)
                    array unset QWIKMD::basicGui live
                }
                if {[info exist QWIKMD::basicGui(solvent,0)] == 1} {
                    set QWIKMD::basicGui(solvent,$QWIKMD::run,0) $QWIKMD::basicGui(solvent,0)
                    set QWIKMD::basicGui(saltions,$QWIKMD::run,0) $QWIKMD::basicGui(saltions,0)
                    set QWIKMD::basicGui(saltconc,$QWIKMD::run,0) $QWIKMD::basicGui(saltconc,0)

                    set QWIKMD::advGui(solvent,$QWIKMD::run,0) $QWIKMD::advGui(solvent,0)
                    set QWIKMD::advGui(saltions,$QWIKMD::run,0) $QWIKMD::advGui(saltions,0)
                    set QWIKMD::advGui(saltconc,$QWIKMD::run,0) $QWIKMD::advGui(saltconc,0) 

                    array unset QWIKMD::basicGui solvent,0
                    array unset QWIKMD::basicGui saltions,0
                    array unset QWIKMD::basicGui saltconc,0
                    array unset QWIKMD::advGui solvent,0
                    array unset QWIKMD::advGui saltions,0
                    array unset QWIKMD::advGui saltconc,0
                }
                QWIKMD::selectNotebooks 0
                set tabid [$QWIKMD::topGui.nbinput index current]
                if {[catch {glob ${QWIKMD::outPath}/run/*.dcd} listprot] == 0 && $QWIKMD::run != "MDFF" && $QWIKMD::prepared == 1} {
                    
                    ## window to select which protocols to load 
                    QWIKMD::LoadOptBuild $tabid dcd
                    
                    $QWIKMD::topGui.nbinput select $tabid
                    if {$QWIKMD::loadprotlist == "Cancel"} {
                        QWIKMD::resetBtt 2
                        return
                    }
                    set seltext "all"
                    set sufix ""
                    set docatdcd 0
                    if {$QWIKMD::loadlaststep == 0} {
                        ## check if any catdcd function was selected (remove waters, ions or hydrogens)
                        if {$QWIKMD::loadremovewater == 1 } {
                            append seltext " and not water "
                            set sufix "_nowater"
                            set docatdcd 1
                        }
                        if {$QWIKMD::loadremoveions == 1} {
                            append seltext " and not (ions not within 5 of protein)" 
                            append sufix "_noions"
                            set docatdcd 1

                        }
                        if {$QWIKMD::loadremovehydrogen == 1} {
                            append seltext " and noh" 
                            append sufix "_noh"
                            set docatdcd 1

                        }
                    }
                    set newloadprotlist [list]
                    set psf [file root [lindex $QWIKMD::inputstrct 0]].psf
                    set pdb [file root [lindex $QWIKMD::inputstrct 0]].pdb
                    ## call catdcd and generate the pdb and psf for the dcd
                    if {$docatdcd == 1} {
                        
                        set psf [file root [lindex $QWIKMD::inputstrct 0]]$sufix.psf
                        set pdb [file root [lindex $QWIKMD::inputstrct 0]]$sufix.pdb
                        if {[file exists [file root [lindex $QWIKMD::inputstrct 0]]$sufix.psf] == 0} {
                            set sel [atomselect $QWIKMD::topMol $seltext frame 0] 
                            $sel writepsf $psf
                            $sel writepdb $pdb
                            set indexfile [open "catdcd_index.txt" w+]
                            puts $indexfile [$sel get index]
                            close $indexfile
                            $sel delete
                        }
                        set warning 0
                        for {set i 0} {$i < [llength $QWIKMD::loadprotlist]} {incr i} {
                            set indcd [lindex $QWIKMD::loadprotlist $i].dcd
                            #if {[file exists $indcd] == 1} {
                            set outcd [lindex $QWIKMD::loadprotlist $i]$sufix.dcd
                            if {[file exists $outcd] == 0} {
                                if {$warning == 0} {
                                    set answer [tk_messageBox -message "Save trajectories of a subset of atoms may take some time.\
                                    \nThis process only happens once for the same subset of atoms. Do you want to continue?" -type yesno\
                                     -title "Load trajectory" -parent $QWIKMD::topGui]
                                    if {$answer == "no"} {
                                        mol delete $QWIKMD::topMol
                                        return
                                    }
                                    set warning 1
                                }
                                set location ""
                                if {[catch {glob $env(VMDDIR)/plugins/[vmdinfo arch]/bin/catdcd*} location] == 0} {
                                    catch {eval "exec ${location}/catdcd -i catdcd_index.txt -o $outcd $indcd"}
                                }
                            }
                            lappend newloadprotlist [lindex $QWIKMD::loadprotlist $i]$sufix
                            #}
                        }
                    }
                    ## Load initial structure if selected
                    if {$QWIKMD::loadinitialstruct == 0 || $docatdcd == 1} {
                        mol delete $QWIKMD::topMol
                        set inputstrct [list $psf]
                        if {$QWIKMD::loadinitialstruct == 1} {
                            lappend inputstrct $pdb
                        }
                        set QWIKMD::inputstrct $inputstrct
                        QWIKMD::LoadButt $QWIKMD::inputstrct
                    }
                    set dcdlist [list]
                    if {$docatdcd == 1} {
                        set dcdlist $newloadprotlist
                        if {[winfo exists $QWIKMD::advGui(analyze,advance,interradio)] == 1 && ($QWIKMD::loadremovehydrogen == 1 || $QWIKMD::loadremovewater == 1)} {
                            $QWIKMD::advGui(analyze,advance,interradio) configure -state disabled
                        }
                    } else {
                        set dcdlist $QWIKMD::loadprotlist
                    }

                    if {$tabid == 0} {
                        set solvent $QWIKMD::basicGui(solvent,$QWIKMD::run,0)   
                    } else {
                        set solvent $QWIKMD::advGui(solvent,$QWIKMD::run,0)
                    }
                    
                    ## Make sure no other dcd frame is loaded. Important for compatibility issues with previous 
                    ## versions of QwikMD
                    set QWIKMD::lastframe [list]
                    if {[molinfo $QWIKMD::topMol get numframes] > 1} {
                        animate delete beg 1 end [molinfo $QWIKMD::topMol get numframes] skip 0 $QWIKMD::topMol
                    }
                    if {$solvent == "Explicit"} {
                        pbc box -off
                    }
        
                    set logfile [open "logfile" w+]
                    for {set i 0} {$i < [llength $dcdlist]} {incr i} {
                        set loadfile [lindex $dcdlist $i]
                        set type ""
                        if {$QWIKMD::loadlaststep == 0} {
                            append loadfile ".dcd"
                            set type dcd
                        } else {
                            append loadfile ".restart.coor"
                            set type namdbin
                        }
                        if {[file exists $loadfile] == 1} {
                            mol addfile $loadfile type $type step $QWIKMD::loadstride waitfor all
                            lappend QWIKMD::lastframe [molinfo $QWIKMD::topMol get numframes]
                            if {$solvent == "Explicit" && $QWIKMD::loadlaststep == 1 } {
                                pbc readxst [lindex $dcdlist $i].restart.xsc -molid $QWIKMD::topMol -last last -step2frame 1
                            }
                        }
                       
                    }
                    close $logfile
                    ## Represent the simulation Box
                    if {$solvent == "Explicit" && [molinfo $QWIKMD::topMol get numframes] > 0} {
                        # pbc box -center bb -color yellow -width 4
                        set QWIKMD::pbcInfo [pbc get -last end -nocheck]
                        pbc box -on
                        update
                        pbc box -center bb -color yellow -width 4
                    }
                    set QWIKMD::confFile $QWIKMD::loadprotlist
                    
                    if {$tabid == 1 && $QWIKMD::run != "MDFF"} {
                        set i 0
                        foreach prtcl $QWIKMD::prevconfFile {
                            if {[lsearch $QWIKMD::confFile $prtcl] == -1} {
                                $QWIKMD::advGui(protocoltb,$QWIKMD::run) rowconfigure $i -foreground grey
                            } else {
                                $QWIKMD::advGui(protocoltb,$QWIKMD::run) rowconfigure $i -foreground black
                            }
                            incr i
                        }
                    }
                }

                if {$QWIKMD::prepared == 1} {
                    QWIKMD::defaultIMDbtt $tabid normal                    
                    QWIKMD::updateTime load
                }
                set numframes [molinfo $QWIKMD::topMol get numframes]
                set index_cmbAux ""
                if {$QWIKMD::prepared == 0} {
                    set chainsAux [array get QWIKMD::chains]
                    set values [array get QWIKMD::index_cmb]
                    ## Remove the saved representation name to avoid conflicts to the new representations. Only the representation type,
                    ## and color are kept
                    set arrayaux ""
                    for {set j 1} {$j < [llength $values]} {incr j 2} {
                        set find [regexp {rep[0-9999]*} [lindex $values $j]]
                        if {$find == 0 } {
                            append arrayaux "[lrange $values [expr $j -1] $j] "
                        }
                    }
                    set index_cmbAux "$arrayaux"
                }
                ## Update values in the main table
                QWIKMD::mainTable [expr [$QWIKMD::topGui.nbinput index current] +1]
                if {$QWIKMD::prepared == 0} {
                    array set QWIKMD::chains $chainsAux
                    array set QWIKMD::index_cmb $index_cmbAux
                }
                update idletasks
                ## Review values in the main table
                QWIKMD::reviewTable [expr [$QWIKMD::topGui.nbinput index current] +1]
                ## Review values in the structure manipulation table
                QWIKMD::SelResid
                
                if {$QWIKMD::prepared == 1} {
                    QWIKMD::lockGUI 
                    if {[file exists "$QWIKMD::outPath/[file tail $QWIKMD::outPath].infoMD"] != 1} {
                        tk_messageBox -title "Missing log File" -message "Text log file not found" -icon warning -parent $QWIKMD::topGui
                        if {[file exists ${QWIKMD::outPath}] == 1} {
                            set QWIKMD::textLogfile [open "$QWIKMD::outPath/[file tail $QWIKMD::outPath].infoMD" a+]
                        }
                    } else {
                        set QWIKMD::textLogfile [open "$QWIKMD::outPath/[file tail $QWIKMD::outPath].infoMD" a+]
                        puts $QWIKMD::textLogfile [QWIKMD::loadDCD]
                        flush $QWIKMD::textLogfile
                    }
                } else {
                    ## Read files from the temporary folder
                    set tempfolder "[file rootname $QWIKMD::basicGui(workdir,0)]_temp"
                    set tempLib ""
                    catch {glob $tempfolder/*.conf} tempLib
                    if {[file isfile [lindex ${tempLib} 0]] == 1} {
                        foreach file $tempLib {
                            catch {file copy -force -- ${file} ${env(QWIKMDTMPDIR)}/}
                        }
                        set tbsize [$QWIKMD::advGui(protocoltb,$QWIKMD::run) size]
                        for {set i 0} {$i < $tbsize} {incr i} {
                            if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$i,lock) == 1} {
                                set  QWIKMD::advGui(protocoltb,$QWIKMD::run,$i,lock) 0
                                QWIKMD::lockUnlockProc $i
                            }
                        }
                    }
                    set listToCopy [list "*.conf" "Renumber_Residues.txt" "*.rtf"]
                    foreach fileList $listToCopy {
                        set cpFile ""
                        catch {glob $tempfolder/$fileList} cpFile
                        if {[file isfile [lindex ${cpFile} 0]] == 1} {
                            foreach file $cpFile {
                                catch {file copy -force -- ${file} ${env(QWIKMDTMPDIR)}/}
                            }
                        }
                        if {$fileList == "*.conf"} {
                            set tbsize [$QWIKMD::advGui(protocoltb,$QWIKMD::run) size]
                            for {set i 0} {$i < $tbsize} {incr i} {
                                if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$i,lock) == 1} {
                                    set  QWIKMD::advGui(protocoltb,$QWIKMD::run,$i,lock) 0
                                    QWIKMD::lockUnlockProc $i
                                }
                            }
                        }
                    }

                    if {$QWIKMD::membraneFrame != ""} {
                        
                        QWIKMD::updateMembraneBox [list $QWIKMD::advGui(membrane,center,x) $QWIKMD::advGui(membrane,center,y) $QWIKMD::advGui(membrane,center,z)]
                        QWIKMD::GenerateMembrane 
                        QWIKMD::DrawBox
                    }
                    QWIKMD::checkStructur load
                }
                ## Update Gui for the current solvent model
                QWIKMD::ChangeSolvent
                display update on
                if {$QWIKMD::run == "MDFF"} {
                    QWIKMD::updateMDFF
                }
            }
            
        } -padding "2 0 2 0"] -row 0 -column 1 -pady 5 -padx 2 -sticky w


    grid [ttk::button $framesetup.fwork.outsave -text "Save" -command {QWIKMD::saveBut save} -padding "2 0 2 0"] -row 0 -column 2 -pady 5 -padx 2 -sticky w

    grid [ttk::frame $framesetup.preparereset] -row 1 -column 0 -pady 1 -sticky ew
    grid columnconfigure $framesetup.preparereset 0 -weight 0
    grid columnconfigure $framesetup.preparereset 1 -weight 1
    grid columnconfigure $framesetup.preparereset 2 -weight 1
    grid columnconfigure $framesetup.preparereset 3 -weight 1
    grid [ttk::button $framesetup.preparereset.button_Prepare -text "Prepare" -padding "4 2 4 2"  -command {
        
        if {$QWIKMD::basicGui(workdir,0) == "Working Directory"} {
            set QWIKMD::basicGui(workdir,0) ""
        }
        
        if {[QWIKMD::PrepareBttProc $QWIKMD::basicGui(workdir,0)] == 0} {
            QWIKMD::changeBCK
            
            QWIKMD::lockGUI
        }
    
    }] -row 0 -column 0 -pady 1 -padx 4 -sticky w
    set tbindex 0
    if {$level != "basic"} {
        set tbindex 1
    } 
    lappend QWIKMD::preparebtt $framesetup.preparereset.button_Prepare
    lappend QWIKMD::livebtt $framesetup.preparereset.live
    grid [ttk::checkbutton $framesetup.preparereset.live -text "Live View" -variable QWIKMD::basicGui(live,$tbindex) -command QWIKMD::checkignoreForces] -row 0 -column 1 -padx 2 -sticky w
    set QWIKMD::basicGui(live,$tbindex) 0

    if {$level == "advanced"} {
        grid [ttk::checkbutton $framesetup.preparereset.ignoreforces -text "Ignore Interactive Forces" -variable QWIKMD::advGui(ignoreforces) -state disabled] -row 0 -column 2 -sticky w
        
        QWIKMD::balloon $framesetup.preparereset.ignoreforces [QWIKMD::ignoreForcesIMD]
        set QWIKMD::advGui(ignoreforces,wdgt) $framesetup.preparereset.ignoreforces
        set QWIKMD::advGui(ignoreforces) 1
    }
    lappend QWIKMD::resetbttwgt $framesetup.preparereset.button_Reset
    grid [ttk::button $framesetup.preparereset.button_Reset -text "Reset" -padding "4 2 4 2"  -command {
        QWIKMD::messageWindow "Reseting QwikMD" "Please wait while QwikMD resets to the \
        default values. This may take some time."
        set tabid [$QWIKMD::topGui.nbinput index current]
        set rbtt [lindex $QWIKMD::resetbttwgt $tabid]
        set lpdb [lindex $QWIKMD::loadpdb $tabid]
        set lqwikmd [lindex $QWIKMD::loadqwikmd $tabid]
        $rbtt configure -state disabled
        $lpdb configure -state disabled
        $lqwikmd configure -state disabled
        display update off
        QWIKMD::resetBtt 2
        ## return to the original window size
        if {$QWIKMD::wmgeom != "" && $QWIKMD::wmgeom != "[winfo reqwidth $QWIKMD::topGui]x[winfo reqheight $QWIKMD::topGui]"} {
            wm geometry $QWIKMD::topGui $QWIKMD::wmgeom
        }
        display update on
        display update ui
        update
        $rbtt configure -state normal
        $lpdb configure -state normal
        $lqwikmd configure -state normal
        destroy $QWIKMD::messWinGui
        set QWIKMD::autorename 1
        return
    }] -row 0 -column 3 -pady 1 -padx 4 -sticky e

    QWIKMD::balloon $framesetup.preparereset.button_Prepare [QWIKMD::prepareBL]
    QWIKMD::balloon $framesetup.preparereset.live [QWIKMD::liveSimulBL]
    QWIKMD::balloon $framesetup.preparereset.button_Reset [QWIKMD::resetBL]


    incr gridrow
    ## Simulation Controls
    grid [ttk::separator $frame.spt -orient horizontal] -row $gridrow -column 0 -sticky ew -pady 2
    incr gridrow
    grid [ttk::frame $frame.fcontrol] -row $gridrow -column 0 -sticky news -pady 0
    grid columnconfigure $frame.fcontrol 0 -weight 1
    grid rowconfigure $frame.fcontrol 0 -weight 1
    grid rowconfigure $frame.fcontrol 1 -weight 1
    ## buttons Exit and Calculate

    grid [ttk::label $frame.fcontrol.prt -text "$QWIKMD::downPoint Simulation Control" ] -row 0 -column 0 -sticky w -pady 0

    bind $frame.fcontrol.prt <Button-1> {
        QWIKMD::hideFrame %W [lindex [grid info %W] 1] "Simulation Control"
    }

    QWIKMD::createInfoButton $frame.fcontrol 0 0

    bind $frame.fcontrol.info <Button-1> {
        set val [QWIKMD::MDControlsinfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow mdControlsinfo [lindex $val 0] [lindex $val 2]
    }

    

    grid [ttk::frame $frame.fcontrol.fcolapse] -row 1 -column 0 -padx 2 -sticky ew
    grid columnconfigure $frame.fcontrol.fcolapse 0 -weight 1

    grid [ttk::frame $frame.fcontrol.fcolapse.f1] -row 1 -column 0 -padx 2 -sticky ew
    grid columnconfigure $frame.fcontrol.fcolapse.f1 0 -weight 1

    set framecontrol $frame.fcontrol.fcolapse.f1


    grid [ttk::frame $framecontrol.run] -row 2 -column 0 -pady 1 -padx 2 -sticky ew
    grid columnconfigure $framecontrol.run 0 -weight 1

    grid [ttk::button $framecontrol.run.button_Calculate -text "Start MD Simulation" -padding "2 2 2 2" -command {
        if {$QWIKMD::prepared == 1} {
            if {$QWIKMD::run == "MDFF"} {
                QWIKMD::updateMDFF
            } else {
                QWIKMD::Run
            }
        } else {
            tk_messageBox -message "Please select and edit your structure and then press\
             \"Prepare\" button." -title "Running Simulation" -icon info -type ok -parent $QWIKMD::topGui
        }
        
    } ] -row 0 -column 0 -pady 1 -padx 2 -sticky ew

    
    QWIKMD::balloon $framecontrol.run.button_Calculate  [QWIKMD::runbuttBL]
    
    grid [ttk::frame $framecontrol.imd] -row 3 -column 0 -pady 1 -padx 2 -sticky ew
    grid columnconfigure $framecontrol.imd 0 -weight 1
    grid columnconfigure $framecontrol.imd 1 -weight 1
    grid columnconfigure $framecontrol.imd 2 -weight 1
    grid [ttk::button $framecontrol.imd.button_Detach -text "Detach" -padding "4 2 4 2"  -command {QWIKMD::Detach}] -row 0 -column 1 -pady 1 -padx 2 -sticky ew

    grid [ttk::button $framecontrol.imd.button_Pause -text "Pause" -padding "4 2 4 2" -command {QWIKMD::Pause}] -row 0 -column 0 -pady 1 -padx 2 -sticky ew
    grid [ttk::button $framecontrol.imd.button_Finish -text "Finish" -padding "4 2 4 2" -command {QWIKMD::Finish}] -row 0 -column 2 -pady 1 -padx 2 -sticky ew

    QWIKMD::balloon $framecontrol.imd.button_Detach  [QWIKMD::detachBL]
    QWIKMD::balloon $framecontrol.imd.button_Pause  [QWIKMD::pauseBL]
    QWIKMD::balloon $framecontrol.imd.button_Finish  [QWIKMD::finishBL]

    lappend QWIKMD::runbtt $framecontrol.run.button_Calculate
    lappend QWIKMD::pausebtt $framecontrol.imd.button_Pause
    lappend QWIKMD::detachbtt $framecontrol.imd.button_Detach
    lappend QWIKMD::finishbtt $framecontrol.imd.button_Finish

    grid [ttk::separator $framecontrol.spt -orient horizontal] -row 4 -column 0 -sticky ew -pady 2

    grid [ttk::frame $framecontrol.progress ] -row 5 -column 0 -pady 2 -sticky nsew
    grid columnconfigure $framecontrol.progress 1 -weight 1

    grid [ttk::label $framecontrol.progress.label -text "Progress"] -column 0 -row 0 -sticky w -padx 2 -pady 2

    grid [ttk::progressbar $framecontrol.progress.pg -mode determinate -variable QWIKMD::basicGui(mdPrec,0)] -column 1 -row 0 -sticky news -pady 0

    grid [ttk::label $framecontrol.progress.currentTimelb -textvariable QWIKMD::basicGui(currenttime,0)] -column 2 -row 0 -sticky w -padx 2 -pady 2

    set QWIKMD::basicGui(mdPrec,0) 0
    if {$level == "basic"} {
        set QWIKMD::basicGui(mdPrec,1) $framecontrol.progress.pg
        set QWIKMD::basicGui(currenttime,pgframe) $framecontrol.progress
    } else {
        $framecontrol.progress.currentTimelb configure -textvariable QWIKMD::basicGui(currenttime,1)
        set QWIKMD::basicGui(mdPrec,2) $framecontrol.progress.pg
        set QWIKMD::advGui(currenttime,pgframe) $framecontrol.progress
    }
    

    set QWIKMD::basicGui(currenttime) "Completed 0.000 of 0.000 ns"
    #########################################################
    ## Update the time displayed in the MD progress 
    ## section. When the qwikMD inputfile is load is
    ## necessary to incr -1 the MD step ($QWIKMD::state)
    ## because the success of the previous MD is only checked
    ## when the Start button is pressed 
    #########################################################
    proc updateTime {opt} {
        set tabid [$QWIKMD::topGui.nbinput index current]
        if {$QWIKMD::basicGui(live,$tabid) == 0} {
            if {$tabid == 0} {
                grid forget $QWIKMD::basicGui(currenttime,pgframe)
            } else {
                grid forget $QWIKMD::advGui(currenttime,pgframe)
            }
        } else {
            set frame $QWIKMD::basicGui(currenttime,pgframe)
            if {$tabid == 1} {
                set frame $QWIKMD::advGui(currenttime,pgframe)
            }
            grid conf $frame -row 5 -column 0 -pady 2 -sticky nsew
            set index $QWIKMD::state
            if {$QWIKMD::state > 0} {
                set index [expr $QWIKMD::state -1]
            }
            set maxtime 0.0
            if {[llength $QWIKMD::maxSteps] > 0} {
                set maxtime [lindex $QWIKMD::maxSteps $index]
            } 
            set tmstep 2
            set const 1e-6
            set label "ns"
            if {$QWIKMD::run == "QM/MM"} {
                set tmstep 0.5
                set const 1e-3
                set label "ps"
            }
            set time [expr ${tmstep}*$const]
            set tottime [QWIKMD::format3Dec [expr ${tmstep}*$const * $maxtime ]]
            set str "Simulation time: [format %.3f [expr $time * [expr $QWIKMD::counterts - $QWIKMD::prevcounterts] * 10] ]\
            of $tottime $label"
            set QWIKMD::basicGui(currenttime,[$QWIKMD::topGui.nbinput index current]) $str
        }
    }  
}
## Update the status of the "Ignore Interactive Forces" button
proc QWIKMD::checkignoreForces {} {
    set tbindex [$QWIKMD::topGui.nbinput index current]
    if {$tbindex == 1} {
        if {$QWIKMD::basicGui(live,$tbindex) == 0} {
            $QWIKMD::advGui(ignoreforces,wdgt) configure -state disabled 
        } elseif {$QWIKMD::run != "MDFF"} {
            $QWIKMD::advGui(ignoreforces,wdgt) configure -state normal 
        } elseif {$QWIKMD::run == "MDFF"} {
            $QWIKMD::advGui(ignoreforces,wdgt) configure -state disabled
            set QWIKMD::advGui(ignoreforces) 1
        }
    } 
} 

### Check if the outputfolder is empty and warn the user that 
### the trajectories will be deleted
proc QWIKMD::checkOutPath {outputfoldername} {
    set answer 0
    if {[file exists ${outputfoldername}/run] == 1} {
        set traj ""
        set trajmsg ""
        catch {glob ${outputfoldername}/run/*.dcd} traj
        if {[file isfile [lindex ${traj} 0]] == 1} {
            set trajmsg " and contains trajectories"
        }
        set answer [tk_messageBox -title "Output folder not empty" -message "The folder ${outputfoldername} is not empty$trajmsg.\
         Do you want to delete this folder?" -type yesno -icon warning -parent $QWIKMD::topGui]

        if {$answer == "yes"} {
            set pwd [pwd]
            if {$pwd == "${outputfoldername}/run" || $pwd == "${outputfoldername}/setup"} {
                if {[catch {cd [file dirname $outputfoldername]}] == 1} {
                    cd $::env(VMDDIR)
                }
            }
            file delete -force -- $outputfoldername
        } elseif {$answer == "no"} {
            set QWIKMD::basicGui(workdir,0) ""
        }
    }
    return $answer
}

## Create *.qwikmd file for MD preparation or just save the work
## to be continued and create the *_temp folder with temporary files
## opt == prepare (proc called from the Prepare button)
## opt == save (proc called from the Save button)
proc QWIKMD::saveBut {opt} {
    global env
    set extension ".qwikmd"
    set types {
        {{QwikMD}       {".qwikmd"}        }
    }
    
    set fil [list]
    set fil [tk_getSaveFile -title "Save InputFile" -filetypes $types -defaultextension $extension]

    if {$fil != ""} {
        set overwrite [QWIKMD::checkOutPath [file rootname $fil]]
        if {$overwrite == "no"} {
            return
        }
    }
    
    if {$fil != "" && $QWIKMD::topMol != ""} {


        if {[string first " " [file tail [file root $fil] ] ] >= 0} {
            tk_messageBox -message "Make sure that space characters are not included in the name of the file"\
             -icon warning -type ok -parent $QWIKMD::topGui
            return
        }
        if {[string range ${fil} [expr [string length ${fil}] -7] end ] != ".qwikmd"} {
            set fil [append fil ".qwikmd"]  
        }
        set QWIKMD::basicGui(workdir,0) $fil

        ## Validate CHARMM Patches and QM commands as they are the only
        ## values coming from a tk::text widget
        if {[$QWIKMD::topGui.nbinput index current] == 1} {
            QWIKMD::validatePatchs
            if {$QWIKMD::run == "QM/MM"} {
                set nlines [expr [lindex [split [$QWIKMD::advGui(qmoptions,ptcqmwdgt) index end] "."] 0] -1]
                set cmdlist [split [$QWIKMD::advGui(qmoptions,ptcqmwdgt) get 1.0 $nlines.end] \n]
                set QWIKMD::advGui(qmoptions,ptcqmval) $cmdlist  
            }
        }

        
        if {$QWIKMD::prepared == 0 && $opt == "save"} {
            set tempfolder "[file rootname $fil]_temp"
            if {[file exists $tempfolder]== 1} {
                cd $::env(VMDDIR)
                file delete -force -- $tempfolder
            }
            file mkdir $tempfolder

            QWIKMD::getOriginalPdb $tempfolder

            set currsel [atomselect $QWIKMD::topMol "all and not name QWIKMDDELETE"]
            set stfile [lindex [molinfo $QWIKMD::topMol get filename] 0]
            set name "[file tail [file root [lindex $stfile 0] ] ]"
            $currsel writepdb $tempfolder/${name}_current.pdb
            set listToCopy [list "*.conf" "Renumber_Residues.txt" "*.rtf"]
            foreach fileList $listToCopy {
                set cpFile ""
                catch {glob $env(QWIKMDTMPDIR)/$fileList} cpFile
                if {[file isfile [lindex ${cpFile} 0]] == 1} {
                    foreach file $cpFile {
                        catch {file copy -force -- ${file} ${tempfolder}/}
                    }
                }
            }
            QWIKMD::SaveInputFile $QWIKMD::basicGui(workdir,0)
        }

        
    }
}

## Search and save the original structure
proc QWIKMD::getOriginalPdb {output} {
    set pdbfile ""
    set stfile [lindex [molinfo $QWIKMD::topMol get filename] 0]
    set name "[file tail [file root [lindex $stfile 0] ] ]_original.pdb"
    ## is it a local file?
    if {[file isfile [lindex $QWIKMD::inputstrct 0] ] == 1 } {
        if {[llength $QWIKMD::inputstrct] == 1} {
            set pdbfile ${QWIKMD::inputstrct}
        } elseif {[llength $QWIKMD::inputstrct] == 2} {
            set pdbfile [lindex $QWIKMD::inputstrct [lsearch $QWIKMD::inputstrct "*.pdb"]]
        }
        if {$pdbfile != ""} {
            file copy -force ${QWIKMD::inputstrct} $output/$name
        }
    } else {
        if {[llength $QWIKMD::inputstrct] == 2} {
            set sel [atomselect top "all and not name QWIKMDDELETE"]
            $sel writepdb $output/$name
            $sel delete
        } else {
            #From autopsf (Get the original pdb from the PDBdata bank)
            set url [format "http://files.rcsb.org/download/%s.pdb" $QWIKMD::inputstrct]
            vmdhttpcopy $url $output/$name
            set failed 0
            if {[file exists $output/$name] == 1} {
                if {[file size $output/$name] == 0} {
                    set failed 1
                }
            } else {
                set failed 0
            }
            if {$failed == 1} {
                file delete -force $output/$name
                tk_messageBox -message "Could not download the original pdb file from PDB DataBank."\
                 -icon error -type ok -parent $QWIKMD::topGui
                return
            }
        }    
    }
}

##############################################
## change color pallet
##############################################
proc QWIKMD::changeScheme {} {
    set repnum 0
    color Element X white
    if {$QWIKMD::topMol != "" && $QWIKMD::topMol == [molinfo top]} {
        set repnum [molinfo $QWIKMD::topMol get numreps]
    } else {
        set QWIKMD::basicGui(scheme) "VMD Classic"
        return
    }
    if {[info exists QWIKMD::basicGui(material)] != 1} {
        catch {molinfo $QWIKMD::topMol get material} QWIKMD::basicGui(material)
        if {[llength $QWIKMD::basicGui(material)] == 0 || [llength $QWIKMD::basicGui(material)] > 1} {
            set QWIKMD::basicGui(material) "Opaque"
        }
    }
    switch $QWIKMD::basicGui(scheme) {
        "VMD Classic" {
            set listcolors [lrange $QWIKMD::colorIdMap 6 end]
            foreach val $listcolors {
                color change rgb [lindex $val 1]
            }
            for {set i 0} {$i < $repnum} {incr i} {
                mol modmaterial $i $QWIKMD::topMol $QWIKMD::basicGui(material)
            }
            mol material $QWIKMD::basicGui(material)

            display shadows $QWIKMD::basicGui(shadows)
            display ambientocclusion $QWIKMD::basicGui(ambientocclusion)
            display cuedensity $QWIKMD::basicGui(cuedensity)
            display rendermode $QWIKMD::basicGui(rendermode)
            color Element C cyan
            color Name C cyan
        }
        default {
            foreach val $QWIKMD::schmColor($QWIKMD::basicGui(scheme)) {
                set color [lindex $val 0]
                set rgb [lindex $val 1]
                color change rgb $color [expr [lindex $rgb 0]/255.0] [expr [lindex $rgb 1]/255.0] [expr [lindex $rgb 2]/255.0]
            }
            set material Opaque
            switch $QWIKMD::basicGui(scheme) {
                Neutral {
                    set material AOEdgy
                }
                QwikMD {
                    set material AOEdgy
                }
                80s {
                    set material AOShiny
                }
                Pastel {
                    set material AOChalky
                }
            }
            for {set i 0} {$i < $repnum} { incr i} {
                mol modmaterial $i $QWIKMD::topMol $material
            }
            mol material $material
            display shadows on
            display ambientocclusion on
            display cuedensity 0.20
            display rendermode GLSL
            color Element C gray
            color Name C gray
        }
    }

}

proc QWIKMD::callStrctManipulationWindow {} {
    if {[winfo exists $QWIKMD::selResGui] != 1} {
        QWIKMD::SelResidBuild
        QWIKMD::SelResid
    } else {
        QWIKMD::SelResidBuild
    }
    raise $QWIKMD::selResGui
    ###############################################################################################
    ## Initiate trace event when the Select Resid window is opend. This event detects 
    ## if a atom was selected in the OpenGl Window and represent it and select in the 
    ## residues table. 
    ## Note!! VMD breaks when the pick event is used and the New Cartoon representation is active.                                                          
    ###############################################################################################
    trace remove variable ::vmd_pick_event write QWIKMD::ResidueSelect
    trace variable ::vmd_pick_event w QWIKMD::ResidueSelect
    mouse mode pick
}
######################################################
## build the simulation option GUI Sections
## Temperature, solvent, salt concentration salt ions
######################################################
proc QWIKMD::system {frame level MD} { 
    grid [ttk::frame $frame.f1] -row 0 -column 0 -stick ew -pady 5
    grid columnconfigure $frame.f1 0 -weight 1
    #grid columnconfigure $frame.f1 1 -weight 1

    grid [ttk::frame $frame.f1.fsolv] -row 0 -column 0 -stick we -pady 5
    grid columnconfigure $frame.f1.fsolv 0 -weight 1
    grid columnconfigure $frame.f1.fsolv 1 -weight 1
    #grid columnconfigure $frame.f1.fsolv 2 -weight 1

    grid [ttk::frame $frame.f1.fsolv.soltype] -row 0 -column 0 -stick we -padx 3
    grid [ttk::label $frame.f1.fsolv.soltype.mSol -text "Solvent"] -row 0 -column 0 -pady 0 -sticky ns
    set values {"Implicit" "Explicit"}
    if {$level != "basic"} {
        set values {"Vacuum" "Implicit" "Explicit"}
    }
    ## Add variable QWIKMD::solvent
    grid [ttk::combobox $frame.f1.fsolv.soltype.combSolv -values $values -width 10 -justify left -state readonly -textvariable QWIKMD::basicGui(solvent,$MD,0)] -row 0 -column 1 -pady 0 -sticky ns
    QWIKMD::balloon $frame.f1.fsolv.soltype.combSolv [QWIKMD::solventBL]

    if {$level != "basic"} {
        if {0} {
            grid [ttk::frame $frame.f1.addMol] -row 0 -column 1 -stick w -pady 5 -padx 3
            grid columnconfigure $frame.f1.addMol 1 -weight 1
            grid [ttk::label $frame.f1.addMol.add -text "Add"] -row 0 -column 0 -stick news -pady 0
            grid [ttk::entry $frame.f1.addMol.addMentry -width 4 -justify right -textvariable QWIKMD::advGui(addmol)] -row 0 -column 1 -stick w -pady 0
            grid [ttk::label $frame.f1.addMol.addMLab -text "molecules of "] -row 0 -column 2 -stick news -pady 0
            grid [ttk::button $frame.f1.addMol.addMBut -text "Browser"] -row 0 -column 3 -stick news -pady 0
            set QWIKMD::advGui(addmol) "10"
        }
        set QWIKMD::advGui(solvent,boxbuffer,$MD) 15
        grid [ttk::frame $frame.f1.fsolv.boxsize] -row 0 -column 1 -stick we -padx 3
        grid columnconfigure $frame.f1.fsolv.boxsize 0 -weight 1

        grid [ttk::frame $frame.f1.fsolv.boxsize.minbox] -row 0 -column 0 -stick we -padx 2
        grid [ttk::checkbutton $frame.f1.fsolv.boxsize.minbox.chckminbox -text "Minimal Box" -variable QWIKMD::advGui(solvent,minimalbox,$MD) -command {
            if {$QWIKMD::advGui(solvent,minimalbox,$QWIKMD::run) == 1} {
                set cmbval {12 13 14 15 16 17 18 19 20}
                $QWIKMD::advGui(solvent,boxbuffer,$QWIKMD::run,entry) configure -values $cmbval
                if {$QWIKMD::advGui(solvent,boxbuffer,$QWIKMD::run) == 6} {
                    set QWIKMD::advGui(solvent,boxbuffer,$QWIKMD::run) 12
                }
            } else {
                set cmbval {6 7 8 9 10 11 12 13 14 15}
                $QWIKMD::advGui(solvent,boxbuffer,$QWIKMD::run,entry) configure -values $cmbval
                if {$QWIKMD::advGui(solvent,boxbuffer,$QWIKMD::run) > 15} {
                    set QWIKMD::advGui(solvent,boxbuffer,$QWIKMD::run) 15
                }
            }
        }] -row 0 -column 0 -stick ns
        set QWIKMD::advGui(solvent,minbox,$MD) $frame.f1.fsolv.boxsize.minbox.chckminbox
        set QWIKMD::advGui(solvent,minimalbox,$MD) 0

        QWIKMD::balloon $frame.f1.fsolv.boxsize.minbox.chckminbox [QWIKMD::minimalBox]
        
        grid [ttk::frame $frame.f1.fsolv.boxsize.buffer] -row 0 -column 1 -stick we -padx 2 -pady 0
        grid [ttk::label $frame.f1.fsolv.boxsize.buffer.add -text "Buffer:"] -row 0 -column 1 -stick ns -pady 0
        set values {6 7 8 9 10 11 12 13 14 15}
        
        grid [ttk::combobox $frame.f1.fsolv.boxsize.buffer.combval -values $values -width 4 -state readonly -textvariable QWIKMD::advGui(solvent,boxbuffer,$MD)] -row 0 -column 2 -sticky ns -padx 2
        grid [ttk::label $frame.f1.fsolv.boxsize.buffer.angs -text "A"] -row 0 -column 3 -stick ns -pady 0
                
        
        bind $frame.f1.fsolv.boxsize.buffer.combval <<ComboboxSelected>> {
            %W selection clear
        }
    }

    grid [ttk::frame $frame.f1.fsalt] -row 1 -column 0 -stick ew -pady 5 -padx 3
    grid columnconfigure $frame.f1.fsalt 0 -weight 1
    grid columnconfigure $frame.f1.fsalt 1 -weight 1
    grid [ttk::frame $frame.f1.fsalt.frmconc] -row 0 -column 0 -stick news -pady 0
    grid [ttk::label $frame.f1.fsalt.frmconc.salC -text "Salt Concentration"] -row 0 -column 0 -stick news -pady 0
    grid [ttk::entry $frame.f1.fsalt.frmconc.salCentry -width 7 -justify right -textvariable QWIKMD::basicGui(saltconc,$MD,0) ] -row 0 -column 1 -stick w -pady 0
    grid [ttk::label $frame.f1.fsalt.frmconc.salCLab -text "mol/L"] -row 0 -column 2 -stick news -pady 0

    QWIKMD::balloon $frame.f1.fsalt.frmconc.salC [QWIKMD::saltConceBL]
    QWIKMD::balloon $frame.f1.fsalt.frmconc.salCentry [QWIKMD::saltConceBL]

    grid [ttk::frame $frame.f1.fsalt.fcomb] -row 0 -column 1 -stick nes -pady 0

    grid [ttk::label $frame.f1.fsalt.fcomb.flsalt -text "Choose Salt"] -row 0 -column 0 -stick ns -pady 0
    set values {NaCl KCl}
    grid [ttk::combobox $frame.f1.fsalt.fcomb.combSalt -width 10 -justify left -values $values -state readonly -textvariable QWIKMD::basicGui(saltions,$MD,0)] -row 0 -column 1 -pady 0
    
    QWIKMD::createInfoButton $frame.f1 0 2

    bind $frame.f1.info <Button-1> {
        set val [QWIKMD::mdSmdInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow mdSmdInfo [lindex $val 0] [lindex $val 2]
    }

    if {$level == "basic"} {
        set QWIKMD::basicGui(solvent,$MD,0) "Implicit"
        set QWIKMD::basicGui(solvent,$MD) $frame.f1.fsolv.soltype.combSolv

        set QWIKMD::basicGui(saltions,$MD,0) "NaCl"
        set QWIKMD::basicGui(saltions,$MD) $frame.f1.fsalt.fcomb.combSalt

        set QWIKMD::basicGui(saltconc,$MD,0) "0.15"
        set QWIKMD::basicGui(saltconc,$MD) $frame.f1.fsalt.frmconc.salCentry
    } else {
        set QWIKMD::advGui(solvent,$MD,0) "Explicit"
        $frame.f1.fsolv.soltype.combSolv configure -textvariable QWIKMD::advGui(solvent,$MD,0)
        set QWIKMD::advGui(solvent,$MD) $frame.f1.fsolv.soltype.combSolv

        set QWIKMD::advGui(saltions,$MD,0) "NaCl"
        $frame.f1.fsalt.fcomb.combSalt configure -textvariable QWIKMD::advGui(saltions,$MD,0)
        set QWIKMD::advGui(saltions,$MD) $frame.f1.fsalt.fcomb.combSalt

        set QWIKMD::advGui(saltconc,$MD,0) "0.15"
        $frame.f1.fsalt.frmconc.salCentry configure -textvariable QWIKMD::advGui(saltconc,$MD,0)
        set QWIKMD::advGui(saltconc,$MD) $frame.f1.fsalt.frmconc.salCentry

        set QWIKMD::advGui(solvent,boxbuffer,$MD,entry) $frame.f1.fsolv.boxsize.buffer.combval
    }


    QWIKMD::balloon $frame.f1.fsalt.fcomb.combSalt [QWIKMD::saltTypeBL]

    bind $frame.f1.fsolv.soltype.combSolv <<ComboboxSelected>> {
        if {$QWIKMD::prepared == 0} {
            QWIKMD::ChangeSolvent
        }
        %W selection clear
    }
    bind $frame.f1.fsalt.fcomb.combSalt <<ComboboxSelected>> {
        %W selection clear  
    }
    $frame.f1.fsalt.fcomb.combSalt configure -state disabled
}

############################################################
## Add frames to the simulation notebook inside the Run tab
############################################################


proc QWIKMD::hideFrame {w frame txt} {
    set frameaux "$frame.fcolapse"
    set arrow [lindex [$w cget -text] 0]
    if {$arrow != $QWIKMD::rightPoint} {
        $w configure -text "$QWIKMD::rightPoint $txt"
        grid forget $frameaux
        set info [grid info [lindex [grid info $w] 1] ]
        grid rowconfigure [lindex $info 1] [lindex $info 5] -weight 0
    } else {
        $w configure -text "$QWIKMD::downPoint $txt"
        set info [grid info $w]
        grid conf $frameaux -row [expr [lindex $info 5] +1] -column [lindex $info 3] -pady 1 -padx 2 -sticky ewns
        set info [grid info [lindex [grid info $w] 1] ]
        grid rowconfigure [lindex $info 1] [lindex $info 5] -weight 1
    }
}

#################################
## Build Basic Run protocol tabs
#################################    
proc QWIKMD::protocolBasic {frame PRT} {

    ############################################################
    ## First the common widgets between SMD and MD are created
    ## and then, inside the if statement, the specific widgets 
    ## are created
    ############################################################

    ## Frame Protocol
    grid [ttk::frame $frame.f2] -row 1 -column 0 -sticky ew -pady 2
    grid columnconfigure $frame.f2 0 -weight 1
    
    grid [ttk::label $frame.f2.prt -text "$QWIKMD::rightPoint Protocol"] -row 0 -column 0 -sticky w -pady 2
    
    grid [ttk::frame $frame.f2.fcolapse] -row 1 -column 0 -sticky ew -pady 2
    grid columnconfigure $frame.f2.fcolapse 0 -weight 1

    grid rowconfigure $frame.f2.fcolapse 3 -weight 1
    bind $frame.f2.prt <Button-1> {
        QWIKMD::hideFrame %W [lindex [grid info %W] 1] "Protocol"
    }

    set framecolapse $frame.f2.fcolapse

    grid [ttk::frame $framecolapse.sep] -row 0 -column 0 -sticky ew -pady 2
    grid columnconfigure $framecolapse.sep 0 -weight 1

    grid [ttk::separator $framecolapse.sep.spt -orient horizontal] -row 0 -column 0 -sticky ew -pady 0

    if {$PRT != "MDFF"} {

        grid [ttk::frame $framecolapse.fcheck] -row 1 -column 0 -sticky news -padx 0 -pady 0
        grid columnconfigure $framecolapse.fcheck 3 -weight 1

        grid [ttk::checkbutton $framecolapse.fcheck.min -text "Equilibration" -variable QWIKMD::basicGui(prtcl,$PRT,equi)] -row 0 -column 0 -sticky ew -padx 2
        grid [ttk::checkbutton $framecolapse.fcheck.md -text "MD" -variable QWIKMD::basicGui(prtcl,$PRT,md)] -row 0 -column 1 -sticky ew -padx 2
        set QWIKMD::basicGui(prtcl,$PRT,equibtt) $framecolapse.fcheck.min
        set QWIKMD::basicGui(prtcl,$PRT,mdbtt) $framecolapse.fcheck.md
        grid [ttk::frame $framecolapse.sep2] -row 2 -column 0 -sticky ew -pady 2
        grid columnconfigure $framecolapse.sep2 0 -weight 1
        grid [ttk::separator $framecolapse.sep2.spt -orient horizontal] -row 0 -column 0 -sticky ew -pady 0
        
        QWIKMD::balloon $framecolapse.fcheck.min [QWIKMD::EquiMDBL]
        QWIKMD::balloon $framecolapse.fcheck.md [QWIKMD::mdMDBL]

        QWIKMD::createInfoButton $framecolapse.fcheck 0 3
        bind $framecolapse.fcheck.info <Button-1> {
            set val [QWIKMD::protocolMDInfo]
            set QWIKMD::link [lindex $val 1]
            QWIKMD::infoWindow protocolMDInfo [lindex $val 0] [lindex $val 2]
        }
        set QWIKMD::basicGui(mdsmdinfo,$PRT) $framecolapse.fcheck.info
        set QWIKMD::basicGui(prtcl,$PRT,equi) 1
        set QWIKMD::basicGui(prtcl,$PRT,md) 1
        if {$PRT != "SMD"} {
            set QWIKMD::basicGui(prtcl,$PRT,smd) 0
        } else {
            set QWIKMD::basicGui(prtcl,$PRT,smd) 1
        }
        
    } else {
        QWIKMD::createInfoButton  $frame.f2 0 0
        bind $frame.f2.info <Button-1> {
            set val [QWIKMD::protocolMDFFInfo]
            set QWIKMD::link [lindex $val 1]
            QWIKMD::infoWindow protocolMDFFInfo [lindex $val 0] [lindex $val 2]
        }
        set QWIKMD::advGui(mdsmdinfo,$PRT) $frame.f2.info
    }

    grid [ttk::frame $framecolapse.fopt] -row 3 -column 0 -sticky ew -pady 5
    grid columnconfigure $framecolapse.fopt 0 -weight 1
    grid rowconfigure $framecolapse.fopt 1 -weight 1

    grid [ttk::frame $framecolapse.fopt.temp] -row 0 -column 0 -sticky ew
    grid [ttk::label $framecolapse.fopt.temp.ltemp -text "Temperature" -justify center] -row 0 -column 0 -sticky ew 

    #####################################################################
    ## The format procs are outside the validatecommand because inside 
    ## the validate command definition, the format command does not work 
    #####################################################################
    proc format5Dec {val} {
        return [format %.5f [expr double(round(100000*$val))/100000]]
    }
    proc format4Dec {val} {
        return [format %.4f [expr double(round(10000*$val))/10000]]
    }
    proc format3Dec {val} {
        return [format %.3f [expr double(round(1000*$val))/1000]]
    }
    proc format2Dec {val} {
        return [format %.2f [expr double(round(100*$val))/100]]
    }
    
    proc format0Dec {val} {
        return [format %.0f [expr double(round(1*$val))/1]]
    }
    set QWIKMD::basicGui(temperature,$PRT,0) "27"
    grid [ttk::entry $framecolapse.fopt.temp.entrytemp -width 7 -justify right -textvariable QWIKMD::basicGui(temperature,$PRT,0) -validate focusout -validatecommand {
        
        if {[info exists QWIKMD::basicGui(temperature,$QWIKMD::run)]} {
            $QWIKMD::basicGui(temperature,$QWIKMD::run) configure -text [expr $QWIKMD::basicGui(temperature,$QWIKMD::run,0) + 273]
            $QWIKMD::basicGui(temperature,$QWIKMD::run) configure -text [expr $QWIKMD::basicGui(temperature,$QWIKMD::run,0) + 273]
        }

        return 1
        }] -row 0 -column 1 -sticky ew 
        
    grid [ttk::label $framecolapse.fopt.temp.lcent -text "C"] -row 0 -column 2 -sticky w 

    grid [ttk::frame $framecolapse.fopt.temp.kelvin] -row 0 -column 3 -sticky w
    grid [ttk::label $framecolapse.fopt.temp.kelvin.ltempkelvin -justify center -text [expr $QWIKMD::basicGui(temperature,$PRT,0) + 273]] -row 0 -column 0 -sticky w -padx 2 
    grid [ttk::label $framecolapse.fopt.temp.kelvin.k -text "K" -justify center] -row 0 -column 1 -sticky w

    set QWIKMD::basicGui(prtcl,$PRT,mdtemp) $framecolapse.fopt.temp.entrytemp
    QWIKMD::balloon $framecolapse.fopt.temp.ltemp [QWIKMD::mdTemperatureBL]
    QWIKMD::balloon $framecolapse.fopt.temp.entrytemp [QWIKMD::mdTemperatureBL]

    set QWIKMD::basicGui(temperature,$PRT) $framecolapse.fopt.temp.kelvin.ltempkelvin
    if {$PRT == "MD"} {

        grid [ttk::label $framecolapse.fopt.temp.ltime -text "Simulation Time" -justify center] -row 1 -column 0 -sticky ew 
        
        grid [ttk::entry $framecolapse.fopt.temp.entrytime -width 7 -justify right -validate focusout -textvariable QWIKMD::basicGui(mdtime,0) -validatecommand {
            set val [QWIKMD::format0Dec [expr $QWIKMD::basicGui(mdtime,0) / 2e-6]]
            set mod [expr fmod($val,10)]
            if { $mod != 0.0} { 
                set QWIKMD::basicGui(mdtime,0) [QWIKMD::format5Dec [expr [expr $val + {10 - $mod}] * 2e-6 ] ]
                return 0
            } else {
                return 1
            }
            }] -row 1 -column 1 -sticky ew 
        grid [ttk::label $framecolapse.fopt.temp.lns -text "ns"] -row 1 -column 2 -sticky ew 
        set QWIKMD::basicGui(prtcl,$PRT,mdtime) $framecolapse.fopt.temp.entrytime
        set QWIKMD::basicGui(mdtime,0) "10.0"
        QWIKMD::balloon $framecolapse.fopt.temp.ltime [QWIKMD::mdMaxTimeBL]
        QWIKMD::balloon $framecolapse.fopt.temp.entrytime [QWIKMD::mdMaxTimeBL]
    } elseif {$PRT == "SMD"} {

        $framecolapse.fcheck.md configure -text "MD"

        QWIKMD::balloon $framecolapse.fcheck.md [QWIKMD::smdEqMDBL]
        grid [ttk::checkbutton $framecolapse.fcheck.smd -text "SMD" -variable QWIKMD::basicGui(prtcl,$PRT,smd)] -row 0 -column 2 -sticky ew -padx 2

        set QWIKMD::basicGui(prtcl,$PRT,smd) 1
        set QWIKMD::basicGui(prtcl,$PRT,smdbtt) $framecolapse.fcheck.smd
        QWIKMD::balloon $framecolapse.fcheck.smd [QWIKMD::smdSMDBL]

        QWIKMD::addSMDVD $framecolapse.fopt.temp 1 0
        set QWIKMD::basicGui(prtcl,$PRT,smdlength) $framecolapse.fopt.temp.entryLength 
        set QWIKMD::basicGui(prtcl,$PRT,smdvel) $framecolapse.fopt.temp.entryvel 

        QWIKMD::addSMDAP $framecolapse.fopt.temp 0 4

        grid [ttk::label $framecolapse.fopt.temp.mtime -text "Simulation Time" -justify center] -row 3 -column 0 -sticky ew 
        grid [ttk::entry $framecolapse.fopt.temp.entrytime -width 7 -justify right -textvariable QWIKMD::basicGui(mdtime,1) -validate focus -validatecommand {QWIKMD::reviewLenVelTime 3} ] -row 3 -column 1 -sticky ew 
        grid [ttk::label $framecolapse.fopt.temp.lmaxTime -text "ns" ] -row 3 -column 2 -sticky ew
        QWIKMD::balloon $framecolapse.fopt.temp.mtime [QWIKMD::mdMaxTimeBL]
        QWIKMD::balloon $framecolapse.fopt.temp.entrytime [QWIKMD::mdMaxTimeBL]

        set QWIKMD::basicGui(prtcl,$PRT,mdtime) $framecolapse.fopt.temp.entrytime
        set QWIKMD::basicGui(mdtime,1) 0
    } elseif {$PRT == "MDFF"} {
        ## MDFF tab is located in the advanced run tab,
        ## but its structure has more in common with the basic run tab
        grid configure $frame.f2 -sticky nsew 
        grid rowconfigure $frame.f2 1 -weight 1
        
        grid configure $framecolapse -sticky nsew 
        grid rowconfigure $framecolapse 1 -weight 0
        grid rowconfigure $framecolapse 2 -weight 0

        grid configure $framecolapse.fopt -sticky nsew 
        grid rowconfigure $framecolapse.fopt 1 -weight 2
        grid rowconfigure $framecolapse.fopt 0 -weight 0

        grid [ttk::label $framecolapse.fopt.temp.mintime -text "Minimization Steps" -justify center] -row 1 -column 0 -sticky ew
        grid [ttk::entry $framecolapse.fopt.temp.entrytime -width 7 -justify right -validate focusout -textvariable QWIKMD::advGui(mdff,min)] -row 1 -column 1 -sticky ew 

        grid [ttk::label $framecolapse.fopt.temp.mdffTime -text "MDFF Steps" -justify center] -row 2 -column 0 -sticky ew
        grid [ttk::entry $framecolapse.fopt.temp.entrymdfftime -width 7 -justify right -validate focusout -textvariable QWIKMD::advGui(mdff,mdff)] -row 2 -column 1 -sticky ew 

        set QWIKMD::advGui(mdff,min) 400
        set QWIKMD::advGui(mdff,mdff) 50000

        grid [ttk::frame $framecolapse.fopt.tableframe ] -row 1 -column 0 -sticky nwse -padx 2 -pady 2

        grid columnconfigure $framecolapse.fopt.tableframe  0 -weight 1
        grid rowconfigure $framecolapse.fopt.tableframe  0 -weight 1

        set fro2 $framecolapse.fopt.tableframe 
        option add *Tablelist.activeStyle       frame
        option add *Tablelist.background        gray98
        option add *Tablelist.stripeBackground  #e0e8f0
        option add *Tablelist.setGrid           no
        option add *Tablelist.movableColumns    no

        tablelist::tablelist $fro2.tb \
        -columns { 0 "Fixed" center
                0 "Sec. Structure"   center
                0 "Chirality" center
                0 "Cispeptide" center
                } -yscrollcommand [list $fro2.scr1 set] -xscrollcommand [list $fro2.scr2 set] -showseparators 0 -labelrelief groove  -labelbd 1 -selectbackground white \
                -selectforeground black -foreground black -background white -state normal -selectmode single -stretch "all" -stripebackgroun white -height 2\
                -editstartcommand QWIKMD::startEditMDFF -editendcommand QWIKMD::finishEditMDFF -forceeditendcommand true
        
        $fro2.tb columnconfigure 0 -sortmode dictionary -name Fixed
        $fro2.tb columnconfigure 1 -sortmode real -name SecStrct
        $fro2.tb columnconfigure 2 -sortmode dictionary -name Chiral
        $fro2.tb columnconfigure 3 -sortmode dictionary -name Cispep

        $fro2.tb columnconfigure 0 -width 12 -maxwidth 0 -editable true -editwindow ttk::combobox -wrap true
        $fro2.tb columnconfigure 1 -width 12 -maxwidth 0 -editable true -editwindow ttk::combobox -wrap true
        $fro2.tb columnconfigure 2 -width 12 -maxwidth 0 -editable true -editwindow ttk::combobox -wrap true
        $fro2.tb columnconfigure 3 -width 12 -maxwidth 0 -editable true -editwindow ttk::combobox -wrap true

        ##Scrool_BAr V
        scrollbar $fro2.scr1 -orient vertical -command [list $fro2.tb  yview]
        grid $fro2.scr1 -row 0 -column 1  -sticky ens

        ## Scrool_Bar H
        scrollbar $fro2.scr2 -orient horizontal -command [list $fro2.tb xview]
        grid $fro2.scr2 -row 1 -column 0 -sticky swe

        grid $fro2.tb -row 0 -column 0 -sticky news
        grid columnconfigure $fro2.tb 0 -weight 1; grid rowconfigure $fro2.tb 0 -weight 1

        set QWIKMD::advGui(protocoltb,$PRT) $fro2.tb

        $fro2.tb insert end {none "same fragment as protein" "same fragment as protein" "same fragment as protein"}

     } 
     grid forget $framecolapse
}
##################################################
## commands used by tablelist during cell edition
## on MDFF tab
##################################################
proc QWIKMD::startEditMDFF {tbl row col text} {
    set w [$tbl editwinpath]
    set values [list]
    switch [$tbl columncget $col -name] {
        Fixed {
            set values {none all "From List"}
            $w configure -values $values -state normal -style protocol.TCombobox -takefocus 0 -exportselection false -justify center
        }
        SecStrct {
            set values {none "same fragment as protein"}
            $w configure -values $values -state readonly -style protocol.TCombobox -takefocus 0 -exportselection false -justify center
        }
        Chiral {
            set values {none "same fragment as protein"}
            $w configure -values $values -state readonly -style protocol.TCombobox -takefocus 0 -exportselection false -justify center
        }
        Cispep {
            set values {none "same fragment as protein"}
            $w configure -values $values -state readonly -style protocol.TCombobox -takefocus 0 -exportselection false -justify center
            
        }
    }
    bind $w <<ComboboxSelected>> {
        $QWIKMD::advGui(protocoltb,$QWIKMD::run) finishediting  
    }
    $w set $text
    return $text
}

proc QWIKMD::finishEditMDFF {tbl row col text} {
    set w [$tbl editwinpath]
    if {[molinfo num] == 0} {
        $w selection clear
        return $text
    }
    switch [$tbl columncget $col -name] {
        Fixed {
            if {$text == "From List"} {
                set QWIKMD::anchorpulling 0
                set QWIKMD::buttanchor 0
                set QWIKMD::selResidSel "Type Selection"
                QWIKMD::selResidForSelection "MDFF Fixed Selection" [list]
                $tbl rejectinput
            } else {
                if {[lsearch {none all "From List"} $text] == -1} {
                    set checkOk [QWIKMD::checkSelection $w protocol.TEntry]
                    if !$checkOk {
                        set text "none"
                        ttk::style configure protocol.TCombobox -foreground black
                    }
                }
            }
        }
        SecStrct {
            return $text
        }
        Chiral {
            return $text
        }
        Cispep {
            return $text
        }
    }
    
    return $text
}
####################################
## Build Advanced Run protocol tabs
####################################
proc QWIKMD::protocolAdvanced {frame PRT} {

    ## Frame Protocol
    grid [ttk::frame $frame.f2] -row 1 -column 0 -sticky ewns -pady 2
    grid columnconfigure $frame.f2 0 -weight 1
    grid rowconfigure $frame.f2 0 -weight 0
    grid rowconfigure $frame.f2 1 -weight 1
    grid [ttk::label $frame.f2.prt -text "$QWIKMD::rightPoint Protocol"] -row 0 -column 0 -sticky w -pady 2

    bind $frame.f2.prt <Button-1> {
        QWIKMD::hideFrame %W [lindex [grid info %W] 1] "Protocol"
    }

    QWIKMD::createInfoButton $frame.f2 0 0
    bind $frame.f2.info <Button-1> {
        set val [QWIKMD::protocolMDInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow protocolMDInfo [lindex $val 0] [lindex $val 2]
    }
    set QWIKMD::advGui(mdsmdinfo,$PRT) $frame.f2.info

    grid [ttk::frame $frame.f2.fcolapse ] -row 1 -column 0 -sticky ewns -pady 2
    grid columnconfigure $frame.f2.fcolapse 0 -weight 1
    grid rowconfigure $frame.f2.fcolapse 0 -weight 1

    grid [ttk::frame $frame.f2.fcolapse.tableframe ] -row 0 -column 0 -sticky nwse -padx 4

    grid columnconfigure $frame.f2.fcolapse.tableframe 0 -weight 1
    grid rowconfigure $frame.f2.fcolapse.tableframe 0 -weight 1

    set fro2 $frame.f2.fcolapse.tableframe
    option add *Tablelist.activeStyle       frame
    option add *Tablelist.background        gray98
    option add *Tablelist.stripeBackground  #e0e8f0
    option add *Tablelist.setGrid           no
    option add *Tablelist.movableColumns    no

        tablelist::tablelist $fro2.tb \
        -columns { 0 "Protocol"  center
                0 "n Steps"  center
                0 "Restraints" center
                0 "Ensemble" center
                0 "Temp (C)" center 
                0 "Pressure (atm)" center 
                } -yscrollcommand [list $fro2.scr1 set] -xscrollcommand [list $fro2.scr2 set] -showseparators 0 -labelrelief groove  -labelbd 1 -selectbackground cyan \
                -selectforeground black -foreground black -background white -state normal -selectmode single -stretch "0 1 2" -stripebackgroun white -height 5 \
                -editstartcommand QWIKMD::cellStartEditPtcl -editendcommand QWIKMD::cellEndEditPtcl -forceeditendcommand true -editselectedonly true

    $fro2.tb columnconfigure 0 -sortmode dictionary -name Protocol
    $fro2.tb columnconfigure 1 -sortmode real -name nSteps
    $fro2.tb columnconfigure 2 -sortmode dictionary -name Restraints
    $fro2.tb columnconfigure 3 -sortmode dictionary -name Ensemble
    $fro2.tb columnconfigure 4 -sortmode real -name Temp
    $fro2.tb columnconfigure 5 -sortmode real -name Pressure

    $fro2.tb columnconfigure 0 -width 12 -maxwidth 0 -editable true -editwindow ttk::combobox 
    $fro2.tb columnconfigure 1 -width 0 -maxwidth 0 -editable true -editwindow spinbox
    $fro2.tb columnconfigure 2 -width 20 -maxwidth 0 -editable true -editwindow ttk::combobox -wrap true
    $fro2.tb columnconfigure 3 -width 0 -maxwidth 0 -editable true -editwindow ttk::combobox -wrap true
    $fro2.tb columnconfigure 4 -width 0 -maxwidth 0 -editable true -editwindow spinbox
    $fro2.tb columnconfigure 5 -width 0 -maxwidth 0 -editable true -editwindow spinbox
    
    grid $fro2.tb -row 0 -column 0 -sticky news
    grid columnconfigure $fro2.tb 0 -weight 1; grid rowconfigure $fro2.tb 0 -weight 1

    ##Scrool_BAr V
    scrollbar $fro2.scr1 -orient vertical -command [list $fro2.tb  yview]
     grid $fro2.scr1 -row 0 -column 1  -sticky ens

    ## Scrool_Bar H
    scrollbar $fro2.scr2 -orient horizontal -command [list $fro2.tb xview]
    grid $fro2.scr2 -row 1 -column 0 -sticky swe

    bind [$fro2.tb bodytag] <Double-Button-1>  {
        [tablelist::getTablelistPath  %W] selection clear 0 end
    }

    ## Bind the table labels with text for the balloons 
    bind [$fro2.tb labeltag] <Any-Enter> {
        set col [tablelist::getTablelistColumn %W]
        set help 0
        switch $col {
            0 {
                set help [QWIKMD::selTabelProtocol]
            }
            1 {
                set help [QWIKMD::selTabelNSteps]
            }
            2 {
                set help [QWIKMD::selTabelRestraints]
            }
            3 {
                set help [QWIKMD::selTabelEnsemble]
            }
            4 {
                set help [QWIKMD::mdTemperatureBL]
            }
            5 {
                set help [QWIKMD::selTabelPressure]
            }
            default {
                set help $col
            }
        }
        after 1000 [list QWIKMD::balloon:show %W $help]
  
    }
    bind [$fro2.tb labeltag] <Any-Leave> "destroy %W.balloon"

    grid [ttk::frame $frame.f2.fcolapse.editProtocol] -row 1 -column 0 -sticky e    

    grid [ttk::button $frame.f2.fcolapse.editProtocol.clear -text "Clear" -padding "0 0 0 0" -command  {
        ## Clear protocol table
        set tabid [$QWIKMD::topGui.nbinput index current]
        if {$QWIKMD::load == 0 || $tabid != [lindex [lindex $QWIKMD::selnotbooks 0] 1]\
            || [$QWIKMD::topGui.nbinput.f[expr $tabid +1].nb index current]  != [lindex [lindex $QWIKMD::selnotbooks 1] 1] } {
            $QWIKMD::advGui(protocoltb,$QWIKMD::run) delete 0 end
            array unset QWIKMD::advGui protocoltb,$QWIKMD::run,*
            for {set i 0} {$i < 4} {incr i} {
                QWIKMD::addProtocol
            }
            catch {glob $env(QWIKMDTMPDIR)/*.conf} tempLib
            if {[file isfile [lindex ${tempLib} 0]] == 1} {
                foreach file $tempLib {
                    file delete -force -- ${file}
                }
            }
        }
    }] -row 0 -column 0 -sticky e -pady 2 -padx 0

    grid [ttk::button $frame.f2.fcolapse.editProtocol.unlock -text "Unlock" -padding "0 0 0 0" -command  {
        set index [$QWIKMD::advGui(protocoltb,$QWIKMD::run) curselection]
        if {$index != ""} {
            QWIKMD::lockUnlockProc $index
        }
    }] -row 0 -column 1 -sticky e -pady 2 -padx 0

    QWIKMD::balloon $frame.f2.fcolapse.editProtocol.unlock [QWIKMD::selProtocolUnlock]

    grid [ttk::button $frame.f2.fcolapse.editProtocol.edit -text "Edit" -padding "0 0 0 0" -command  {
        set QWIKMD::confFile [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 0]
        QWIKMD::editProtocolProc 
    }] -row 0 -column 2 -sticky e -pady 2 -padx 0

    QWIKMD::balloon $frame.f2.fcolapse.editProtocol.edit [QWIKMD::selProtocolEdit]

    grid [ttk::button $frame.f2.fcolapse.editProtocol.add -text "+" -padding "0 0 0 0" -width 4 -command {
        QWIKMD::addProtocol
    }] -row 0 -column 3 -sticky e -pady 2 -padx 0

    QWIKMD::balloon $frame.f2.fcolapse.editProtocol.add [QWIKMD::selProtocolAdd]

    grid [ttk::button $frame.f2.fcolapse.editProtocol.delete -text "-" -padding "0 0 0 0" -width 4 -command {
        QWIKMD::deleteProtocol
    }] -row 0 -column 4 -sticky e -pady 2 -padx 0
    
    QWIKMD::balloon $frame.f2.fcolapse.editProtocol.delete [QWIKMD::selProtocolDelete]
    set QWIKMD::advGui(protocoltb,$PRT) $fro2.tb

    if {$PRT == "SMD"} {

        grid [ttk::frame $frame.f2.fcolapse.smdOPT] -row 2 -column 0 -sticky ew
        grid columnconfigure $frame.f2.fcolapse.smdOPT 0 -weight 0
        grid columnconfigure $frame.f2.fcolapse.smdOPT 1 -weight 0
        grid columnconfigure $frame.f2.fcolapse.smdOPT 2 -weight 1
        grid columnconfigure $frame.f2.fcolapse.smdOPT 3 -weight 1
        grid columnconfigure $frame.f2.fcolapse.smdOPT 4 -weight 1
        set QWIKMD::basicGui(prtcl,$PRT,smd) 1

        QWIKMD::addSMDAP $frame.f2.fcolapse.smdOPT 0 0
        QWIKMD::addSMDVD $frame.f2.fcolapse.smdOPT 0 3
        set QWIKMD::advGui(prtcl,$PRT,smdlength) $frame.f2.fcolapse.smdOPT.entryLength 
        set QWIKMD::advGui(prtcl,$PRT,smdvel) $frame.f2.fcolapse.smdOPT.entryvel 

    } elseif {$PRT == "QM/MM"} {
        grid rowconfigure $frame.f2.fcolapse 0 -weight 1
        #grid rowconfigure $frame.f2.fcolapse 2 -weight 1

        grid rowconfigure $frame 1 -weight 1
        grid rowconfigure $frame 2 -weight 1
        grid rowconfigure $frame 3 -weight 1

        grid [ttk::frame $frame.f2.fcolapse.qmmm] -row 2 -column 0 -sticky ewns
        grid columnconfigure $frame.f2.fcolapse.qmmm 0 -weight 1
        grid rowconfigure $frame.f2.fcolapse.qmmm 1 -weight 1

        grid [ttk::frame $frame.f3] -row 2 -column 0 -sticky ewns
        grid columnconfigure $frame.f3 0 -weight 1
        grid rowconfigure $frame.f3 1 -weight 1 

        set str "QM Regions"
        grid [ttk::label $frame.f3.prt -text "$QWIKMD::rightPoint $str"] -row 0 -column 0 -sticky w -pady 2

        bind $frame.f3.prt  <Button-1> {
            QWIKMD::hideFrame %W [lindex [grid info %W] 1] "QM Regions"
        }

        QWIKMD::createInfoButton $frame.f3 0 0
        bind $frame.f3.info <Button-1> {
            set val [QWIKMD::qmRegionsInfo]
            set QWIKMD::link [lindex $val 1]
            QWIKMD::infoWindow qmRegionsInfo [lindex $val 0] [lindex $val 2]
        }

        grid [ttk::frame $frame.f3.fcolapse] -row 1 -column 0 -sticky ewns -pady 2
        grid columnconfigure $frame.f3.fcolapse 0 -weight 1
        grid rowconfigure $frame.f3.fcolapse 0 -weight 1

        grid [ttk::frame $frame.f3.fcolapse.tableframe ] -row 0 -column 0 -sticky nwse -padx 4
        set frmtb $frame.f3.fcolapse.tableframe

        grid columnconfigure $frmtb 0 -weight 1
        grid rowconfigure $frmtb 0 -weight 1

        
        option add *Tablelist.activeStyle       frame
        option add *Tablelist.background        gray98
        option add *Tablelist.stripeBackground  #e0e8f0
        option add *Tablelist.setGrid           no
        option add *Tablelist.movableColumns    no

            tablelist::tablelist $frmtb.tb \
            -columns { 0 "QM ID"  center
                    0 "n Atoms"  center
                    0 "Charge" center
                    0 "Mult" center
                    0 "COM" center 
                    } -yscrollcommand [list $frmtb.scr1 set] -xscrollcommand [list $frmtb.scr2 set] -showseparators 0 -labelrelief groove  -labelbd 1 -selectbackground cyan \
                    -selectforeground black -foreground black -background white -state normal -selectmode single -selecttype cell -stretch "all" -stripebackgroun white -height 3 \
                    -editstartcommand QWIKMD::cellStartEditQMReg -editendcommand QWIKMD::cellEndEditQMReg -forceeditendcommand true -editselectedonly true

        $frmtb.tb columnconfigure 0 -sortmode dictionary -name QMID
        $frmtb.tb columnconfigure 1 -sortmode real -name nAtoms
        $frmtb.tb columnconfigure 2 -sortmode dictionary -name Charge
        $frmtb.tb columnconfigure 3 -sortmode dictionary -name Mult
        $frmtb.tb columnconfigure 4 -sortmode real -name COM 

        $frmtb.tb columnconfigure 0 -width 0 -maxwidth 0 -editable false  
        $frmtb.tb columnconfigure 1 -width 0 -maxwidth 0 -editable false 
        $frmtb.tb columnconfigure 2 -width 0 -maxwidth 0 -editable true 
        $frmtb.tb columnconfigure 3 -width 0 -maxwidth 0 -editable true -editwindow ttk::combobox 
        $frmtb.tb columnconfigure 4 -width 0 -maxwidth 10 -editable false -wrap true
        
        grid $frmtb.tb -row 0 -column 0 -sticky news
        grid columnconfigure $frmtb.tb 0 -weight 1; grid rowconfigure $frmtb.tb 0 -weight 1

        ##Scrool_BAr V
        scrollbar $frmtb.scr1 -orient vertical -command [list $frmtb.tb  yview]
         grid $frmtb.scr1 -row 0 -column 1  -sticky ens

        ## Scrool_Bar H
        scrollbar $frmtb.scr2 -orient horizontal -command [list $frmtb.tb xview]
        grid $frmtb.scr2 -row 1 -column 0 -sticky swe

        bind [$frmtb.tb bodytag] <Double-Button-1>  {
            [tablelist::getTablelistPath  %W] selection clear 0 end
        }

        bind $frmtb.tb <<TablelistSelect>>  {
            set sel [split [$QWIKMD::advGui(qmtable) curcellselection] ","]
            set row [lindex $sel 0]
            set col [lindex $sel 1]
            set qmID [expr $row +1]

            $QWIKMD::advGui(qmtable) selection set $row
            set QWIKMD::advGui(pntchrgopt,qmID) $qmID
            set QWIKMD::advGui(qmtable,tbselected) 1
            
            if {$col == 1} {
                set totalnum [$QWIKMD::advGui(qmtable) cellcget $row,1 -text]
                set QWIKMD::selResidSel $QWIKMD::advGui(qmtable,$qmID,qmRegionSel)
                set QWIKMD::selResidSelIndex $QWIKMD::advGui(qmtable,$qmID,qmRegionSelIndex)
                set QWIKMD::advGui(pntchrgopt,qmsolv) ""
                if {$totalnum == 0} {
                    set QWIKMD::selResidSel "Type Selection"
                    set QWIKMD::advGui(qmtable,$qmID,qmRegionSelIndex) [list]
                    # set QWIKMD::selResidSelRep ""
                }
                
                
                set QWIKMD::advGui(pntchrgopt,qmsolv) $QWIKMD::advGui(qmtable,$qmID,solvDist)
                set QWIKMD::advGui(pntchrgopt,pcDist) $QWIKMD::advGui(qmtable,$qmID,pcDist)
                QWIKMD::selResidForSelection "QM Region Selection #$qmID" $QWIKMD::advGui(qmtable,$qmID,qmRegionSelIndex)
                set tabid [$QWIKMD::topGui.nbinput index current]
                set redef 0
                set tabid [$QWIKMD::topGui.nbinput index current]
                if {$tabid != [lindex [lindex $QWIKMD::selnotbooks 0] 1] || \
                    [$QWIKMD::topGui.nbinput.f[expr ${tabid} +1].nb index current] != [lindex [lindex $QWIKMD::selnotbooks 1] 1]} {
                    set redef 1   
                }
                if {$redef == 1} {
                    $QWIKMD::advGui(atmsel,entry) configure -state normal
                    $QWIKMD::advGui(pntchrgopt,qmsolv,entry) configure -state normal
                }
                
                set QWIKMD::advGui(qmregopt,atmnumb) $totalnum
                set QWIKMD::advGui(pntchrgopt,qmsolv) $QWIKMD::advGui(qmtable,$qmID,solvDist)
                # $QWIKMD::advGui(pntchrgopt,atmnumb) configure -text $QWIKMD::advGui(qmtable,$qmID,qmPtChargesNumAtoms)
                set QWIKMD::advGui(qmtable,tbselected) 0
            } elseif {$col == 4 && $QWIKMD::advGui(qmoptions,lssmode) == "Center of Mass"} {
                

                set QWIKMD::selResidSel $QWIKMD::advGui(qmtable,$qmID,qmCOMSel)
                set QWIKMD::selResidSelIndex $QWIKMD::advGui(qmtable,$qmID,qmCOMIndex)
                QWIKMD::selResidForSelection "Center of Mass Region Selection (#$qmID)" $QWIKMD::advGui(qmtable,$qmID,qmCOMIndex)                
                set QWIKMD::advGui(qmtable,tbselected) 0
            }
            
        }

        set QWIKMD::advGui(qmtable) $frmtb.tb

        grid [ttk::frame $frame.f3.fcolapse.editRegion] -row 1 -column 0 -sticky e    

        grid [ttk::button $frame.f3.fcolapse.editRegion.clear -text "Clear" -padding "0 0 0 0" -command  {
           if {$QWIKMD::load == 0} {
                while {[$QWIKMD::advGui(qmtable) size] > 0} {
                    $QWIKMD::advGui(qmtable) selection set 0
                    QWIKMD::deleteQMregion
                }
            }
        }] -row 0 -column 0 -sticky e -pady 2 -padx 0

        grid [ttk::button $frame.f3.fcolapse.editRegion.add -text "+" -padding "0 0 0 0" -width 4 -command {
            QWIKMD::addQMregion
        }] -row 0 -column 3 -sticky e -pady 2 -padx 0

        QWIKMD::balloon $frame.f3.fcolapse.editRegion.add [QWIKMD::selProtocolAdd]

        grid [ttk::button $frame.f3.fcolapse.editRegion.delete -text "-" -padding "0 0 0 0" -width 4 -command {
            QWIKMD::deleteQMregion
        }] -row 0 -column 4 -sticky e -pady 2 -padx 0


        grid forget $frame.f3.fcolapse


        grid [ttk::frame $frame.f4] -row 3 -column 0 -sticky ewns -pady 2
        grid columnconfigure $frame.f4 0 -weight 1
        grid rowconfigure $frame.f4 1 -weight 1 

        set str "QM Options"
        grid [ttk::label $frame.f4.prt -text "$QWIKMD::rightPoint $str"] -row 0 -column 0 -sticky w -pady 2

        bind $frame.f4.prt  <Button-1> {
            QWIKMD::hideFrame %W [lindex [grid info %W] 1] "QM Options"
        }

        QWIKMD::createInfoButton $frame.f4 0 0
        bind $frame.f4.info <Button-1> {
            set val [QWIKMD::qmOptionsInfo]
            set QWIKMD::link [lindex $val 1]
            QWIKMD::infoWindow qmOptionsInfo [lindex $val 0] [lindex $val 2]
        }

        grid [ttk::frame $frame.f4.fcolapse] -row 1 -column 0 -sticky ewns -pady 2
        grid columnconfigure $frame.f4.fcolapse 0 -weight 1
        grid rowconfigure $frame.f4.fcolapse 1 -weight 1


        set optframe $frame.f4.fcolapse
        grid [ttk::frame $optframe.row0] -row 0 -column 0 -sticky nwes -pady 2
        grid columnconfigure $optframe.row0 1 -weight 1


        grid [ttk::frame $optframe.row0.soft] -row 0 -column 0 -sticky nwes -pady 2
        grid columnconfigure $optframe.row0.soft 0 -weight 1


        grid [ttk::label $optframe.row0.soft.lbl -text "QM Software"] -row 0 -column 0 -sticky nsw
        set values {ORCA MOPAC}
        grid [ttk::combobox $optframe.row0.soft.softval -values $values -width 7 -state readonly -textvariable QWIKMD::advGui(qmoptions,soft) ] -row 0 -column 1 -sticky nsw
        
        set QWIKMD::advGui(qmoptions,soft) "ORCA"
        set QWIKMD::advGui(qmoptions,soft,cmb) $optframe.row0.soft.softval
        ## Check if the path to the qm software is defined
        bind $optframe.row0.soft.softval <<ComboboxSelected>> {
            QWIKMD::checkQMPckgPath 0
            for {set qmID 1} {$qmID <= [$QWIKMD::advGui(qmtable) size]} {incr qmID} {
                if {[QWIKMD::reviewQMCharges $qmID] == 1} {
                    break
                }
            }
            %W selection clear
        }

        grid [ttk::button $optframe.row0.soft.softpath -text "Set Path" -padding "2 0 2 0" -command QWIKMD::setQMPckgPath] -row 0 -column 2 -sticky nsw -padx 2

        set QWIKMD::advGui(qmoptions,stpathbtt) $optframe.row0.soft.softpath

        grid [ttk::frame $optframe.row0.expand] -row 0 -column 1 -sticky we -pady 2
        grid columnconfigure $optframe.row0.expand 0 -weight 1

        grid [ttk::frame $optframe.row0.lss] -row 0 -column 2 -sticky we -pady 2
        grid columnconfigure $optframe.row0.lss 0 -weight 0

        grid [ttk::label $optframe.row0.lss.lbl -text "Live Solv. Mode" ] -row 0 -column 0 -sticky nse
        set values {Off Distance "Center of Mass"}
        grid [ttk::combobox $optframe.row0.lss.val -values $values -width 16 -state readonly -textvariable QWIKMD::advGui(qmoptions,lssmode) ] -row 0 -column 1 -sticky nse

        set QWIKMD::advGui(qmoptions,lssmode) "Off"
        set QWIKMD::advGui(qmoptions,lssmode,cmb) $optframe.row0.lss.val

        bind $optframe.row0.lss.val <<ComboboxSelected>> {
            if {$QWIKMD::advGui(qmoptions,lssmode) != "Off"} {
                set answer [tk_messageBox -message "The use of Live Solvent Mode creates energy peaks.\
                \nAre you sure that you want to use it?" -type yesnocancel -title "Live Solvent Mode" \
                -icon warning -parent $QWIKMD::topGui]
                
                if {$answer != "yes"} {
                    set QWIKMD::advGui(qmoptions,lssmode) "Off"
                    %W selection clear
                    return
                }
            }
            set state 1
            set color black
            if {$QWIKMD::advGui(qmoptions,lssmode) != "Center of Mass"} {
                set state 0
                set color grey
            }
            $QWIKMD::advGui(qmtable) columnconfigure 4 -editable $state -foreground $color -selectforeground $color  
            %W selection clear
        }

        grid [ttk::frame $optframe.row0.qmpcharge] -row 1 -column 0 -sticky nwes -pady 2
        grid columnconfigure $optframe.row0.qmpcharge 0 -weight 0

        grid [ttk::label $optframe.row0.qmpcharge.lbl -text "Point Charges" ] -row 0 -column 0 -sticky nsw
        set values {On Off}
        grid [ttk::combobox $optframe.row0.qmpcharge.val -values $values -width 6 -state readonly -textvariable QWIKMD::advGui(qmoptions,ptcharge) ] -row 0 -column 1 -sticky nsw -padx 6

        set QWIKMD::advGui(qmoptions,ptcharge) On
        set QWIKMD::advGui(qmoptions,ptcharge,cmb) $optframe.row0.qmpcharge.val
        bind $optframe.row0.qmpcharge.val <<ComboboxSelected>> {
            if {$QWIKMD::advGui(qmoptions,ptcharge) == "Off"} {
                set QWIKMD::advGui(qmoptions,switchtype) "Off"
                set QWIKMD::advGui(qmoptions,ptchrgschm) "None"
                set QWIKMD::advGui(qmoptions,cmptcharge) "Off"
            } else {
                set QWIKMD::advGui(qmoptions,switchtype) "Switch"
                set QWIKMD::advGui(qmoptions,ptchrgschm) "Round"
                set QWIKMD::advGui(qmoptions,cmptcharge) "Off"
            }
            %W selection clear
        }

        grid [ttk::label $optframe.row0.qmpcharge.cmlbl -text "Custom PC" ] -row 1 -column 0 -sticky nsw

        set values {On Off}
        grid [ttk::combobox $optframe.row0.qmpcharge.cmval -values $values -width 6 -state readonly -textvariable QWIKMD::advGui(qmoptions,cmptcharge)] -row 1 -column 1 -sticky nsw -padx 6

        set QWIKMD::advGui(qmoptions,cmptcharge) Off
        set QWIKMD::advGui(qmoptions,cmptcharge,cmb) $optframe.row0.qmpcharge.cmval

        bind $optframe.row0.qmpcharge.cmval <<ComboboxSelected>> {
            if {$QWIKMD::advGui(qmoptions,cmptcharge) == "On"} {
                set QWIKMD::advGui(qmoptions,switchtype) "Off"
            } else {
                set QWIKMD::advGui(qmoptions,switchtype) "Switch"
            }
            if {$QWIKMD::advGui(qmoptions,ptcharge) != "Off"} {
                QWIKMD::lockSelResid 0
            } else {
                set QWIKMD::advGui(qmoptions,cmptcharge) "Off"
            }
            %W selection clear
        }

        grid [ttk::frame $optframe.row0.qmreg] -row 1 -column 2 -sticky nwes -pady 2
        grid columnconfigure $optframe.row0.qmreg 0 -weight 0

        grid [ttk::label $optframe.row0.qmreg.lbl -text "QM Switching" ] -row 0 -column 0 -sticky nse
        set values {Off Shift Switch}
        grid [ttk::combobox $optframe.row0.qmreg.val -values $values -width 8 -state readonly -textvariable QWIKMD::advGui(qmoptions,switchtype)] -row 0 -column 1 -sticky nse

        set QWIKMD::advGui(qmoptions,switchtype) "Switch"
        set QWIKMD::advGui(qmoptions,switchtype,cmb) $optframe.row0.qmreg.val

        bind $optframe.row0.qmreg.val <<ComboboxSelected>> {
            if {$QWIKMD::advGui(qmoptions,ptcharge) == "Off"} {
                set QWIKMD::advGui(qmoptions,switchtype) "Off"
            }
            %W selection clear
        }

        grid [ttk::frame $optframe.row0.qmptchrgscheme] -row 2 -column 0 -sticky nwes -pady 2
        grid columnconfigure $optframe.row0.qmptchrgscheme 0 -weight 0

        grid [ttk::label $optframe.row0.qmptchrgscheme.lbl -text "QM Point Charge Scheme" ] -row 0 -column 0 -sticky nse
        set values {None Round Zero}
        grid [ttk::combobox $optframe.row0.qmptchrgscheme.val -values $values -width 8 -state readonly -textvariable QWIKMD::advGui(qmoptions,ptchrgschm)] -row 0 -column 1 -sticky nse

        set QWIKMD::advGui(qmoptions,ptchrgschm) "Round"
        set QWIKMD::advGui(qmoptions,ptchrgschm,cmb) $optframe.row0.qmptchrgscheme.val
        bind $optframe.row0.qmptchrgscheme.val <<ComboboxSelected>> {
            if {$QWIKMD::advGui(qmoptions,ptcharge) == "Off"} {
                set QWIKMD::advGui(qmoptions,ptchrgschm) "None"
            }
            %W selection clear
        }


        grid [ttk::frame $optframe.qmprtcl] -row 1 -column 0 -sticky nwes -pady 2
        grid columnconfigure $optframe.qmprtcl 1 -weight 1
        grid rowconfigure $optframe.qmprtcl 0 -weight 1

        grid [ttk::label $optframe.qmprtcl.lbl -text "QM Command\nLine"] -row 0 -column 0 -sticky nw
        grid [tk::text $optframe.qmprtcl.text -font tkconfixed -wrap none -bg white -height 2 -width 45 -font TkFixedFont -relief flat -foreground black \
    -yscrollcommand [list $optframe.qmprtcl.scr1 set] -xscrollcommand [list $optframe.qmprtcl.scr2 set]] -row 0 -column 1 -sticky wens
        ##Scrool_BAr V
    scrollbar $optframe.qmprtcl.scr1  -orient vertical -command [list $optframe.qmprtcl.text yview]
    grid $optframe.qmprtcl.scr1  -row 0 -column 2  -sticky ens

    ## Scrool_Bar H
    scrollbar $optframe.qmprtcl.scr2  -orient horizontal -command [list $optframe.qmprtcl.text xview]
    grid $optframe.qmprtcl.scr2 -row 0 -column 1 -sticky swe

    set QWIKMD::advGui(qmoptions,ptcqmwdgt) "$optframe.qmprtcl.text"
    $QWIKMD::advGui(qmoptions,ptcqmwdgt) insert 1.0 [format %s "!B3LYP 6-31G* Grid4 PAL[QWIKMD::procs]\n!EnGrad TightSCF"]
    set QWIKMD::advGui(qmoptions,ptcqmval) {"!B3LYP 6-31G* Grid4 PAL[QWIKMD::procs]" "!EnGrad TightSCF"}


    grid forget $frame.f4.fcolapse
    set QWIKMD::advGui(qmtable,QMreg) ""
    }
    grid forget $frame.f2.fcolapse

}
###########################################################################
## Check if the path to the QM software executable is defined
## opt - option to distinguish if it is the combobox calling (opt == 0)
##       or the PrepareBttProc proc (opt == 1)
###########################################################################
proc QWIKMD::checkQMPckgPath {opt} {
    global env
    set pckg $QWIKMD::advGui(qmoptions,soft)
    set do 0
    if {[info exists env(QWIKMD$pckg)] != 1} {
        set do 1
    } elseif {[file exists $env(QWIKMD$pckg)] != 1} {
        set do 1
    }
    if {$opt == 0} {
        $QWIKMD::advGui(qmoptions,ptcqmwdgt) delete 1.0 end
        set text "!B3LYP 6-31G* Grid4 PAL[QWIKMD::procs]\n!EnGrad TightSCF"
        set list {"!B3LYP 6-31G* Grid4 PAL[QWIKMD::procs]" "!EnGrad TightSCF"}
        
        set state 1
        set color black
        if {$pckg == "MOPAC"} {
            set state 0
            set color grey
            set text "PM7 XYZ T=2M 1SCF MOZYME CUTOFF=9.0 AUX LET GRAD QMMM GEO-OK\nTest System"
            set list {"PM7 XYZ T=2M 1SCF MOZYME CUTOFF=9.0 AUX LET GRAD QMMM GEO-OK" "Test System"}
        }
        $QWIKMD::advGui(qmoptions,ptcqmwdgt) insert 1.0 [format %s $text]
        set QWIKMD::advGui(qmoptions,ptcqmval) $list
        #$QWIKMD::advGui(qmtable) cellconfigure $index,[lindex $numcols $i] -editable $state
        $QWIKMD::advGui(qmtable) columnconfigure 3 -editable $state -foreground $color -selectforeground $color    
    }
    if {$do == 1} {
        tk_messageBox -message "The executable file of the QM package $pckg could not be found.\
        \nPlease use the \"Set Path\" button to define the path." -type ok -title "$QWIKMD::advGui(qmoptions,soft) not found."\
         -icon warning -parent $QWIKMD::topGui
    }
    return $do
}
##################################################
## Define the path to the QM software executable
##################################################
proc QWIKMD::setQMPckgPath {} {
    global env
    set fil [tk_getOpenFile -title "$QWIKMD::advGui(qmoptions,soft) executable Path"]
    if {$fil != ""} {
        if {[regexp " " $fil] != 0} {
            tk_messageBox -message "The path to the executable file of the QM package $pckg cannot contain space characters. Please install \
            $pckg in another location." -type ok -title "$QWIKMD::advGui(qmoptions,soft) Path Containing Spaces." \
            -icon warning -parent $QWIKMD::topGui
            return 
        }
        set filename ".qwikmdrc"
        if {[string first "Windows" $::tcl_platform(os)] != -1} {
            set filename "qwikmd.rc"
        }
        file copy -force ${env(HOME)}/$filename ${::env(HOME)}/${filename}_bkup
        set newfile [open ${env(HOME)}/$filename w+]
        puts $newfile "set env(QWIKMDFOLDER) \"[file normalize ${::env(QWIKMDFOLDER)}]\""
        if {[info exists env(QWIKMDTMPDIR)] == 1} {
            puts $newfile "set env(QWIKMDTMPDIR) \"[file normalize ${::env(QWIKMDTMPDIR)}]\""
        }
        foreach pckg [list ORCA MOPAC] {
            set str ""
            if {$pckg != $QWIKMD::advGui(qmoptions,soft)} {
                set var env(QWIKMD$pckg)
                if {[info exists env(QWIKMD$pckg)] == 1} {
                    set str [subst $$var]
                    set env($var) ${str}
                }
            } else {
                set str ${fil}
            }
            if {$str != ""} {
                puts $newfile "set env(QWIKMD$pckg) \"[file normalize ${str}]\""
            }
        }
        close $newfile 
        source ${env(HOME)}/$filename
    }
}
##################################################
## Generate a temp namd conf to be changed
##################################################
proc QWIKMD::editProtocolProc {} {
    global env
    set index [$QWIKMD::advGui(protocoltb,$QWIKMD::run) curselection]
    if {$index != ""} {
        set current [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $index,0 -text]
        set library 0
        if {$QWIKMD::load == 1} {
            set tabid [$QWIKMD::topGui.nbinput index current]
            set prtclselected [$QWIKMD::topGui.nbinput.f[expr ${tabid} +1].nb index current]
            if {$tabid != [lindex [lindex $QWIKMD::selnotbooks 0] 1] || $prtclselected != [lindex [lindex $QWIKMD::selnotbooks 1] 1]} {
                set library 1
            }
        }
        ## library == 1 means that user loaded a previous simulations to prepared another one of a different protocol
        ## newprotocolload  == 1 the user loaded simulation and is creating an extension of the previous protocol
        set newprotocolload 0
        if {$QWIKMD::prepared == 1 && $library == 0 && \
            [file exists ${QWIKMD::outPath}/run/[lindex $QWIKMD::confFile $index].conf] == 0} {
            set newprotocolload 1
        }
        if {$QWIKMD::prepared != 1 || $library == 1 || $newprotocolload == 1} {
            set template ""
            set tempLib ""
            set do [catch {glob $env(QWIKMDFOLDER)/templates/*.conf} tempLib]
            if { $do == 1} {
                set tempLib ""
            } else {
                set tempAux ""
                foreach temp $tempLib {
                    set aux ""
                    regsub -all ".conf" [file root [file tail $temp ] ] "" aux
                    if {$aux != [file root $current]} {
                        lappend tempAux $aux
                    }           
                }
                set tempLib [lsort -dictionary $tempAux]
            }

            set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index) $current
            if {[info exists QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,saveAsTemplate)] == -1} {
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,saveAsTemplate) 0
            }
            set QWIKMD::advGui(protocoltb,template) $QWIKMD::advGui(protocoltb,$QWIKMD::run,$index)
            if {[lindex [split $QWIKMD::advGui(protocoltb,$QWIKMD::run,$index) "."] 1] == ""} {
                ## Window to ask if th user wants to save the temp conf file as a template
                ## and the name of the new file
                set protocol ".protocol"
                if {[winfo exists $protocol] != 1} {
                    toplevel $protocol
                }
                
                grid columnconfigure $protocol 0 -weight 1
                grid rowconfigure $protocol 0 -weight 1
                ## Title of the windows
                wm title $protocol "Save Configuration file As" ;
                set x [expr round([winfo screenwidth .]/2.0)]
                set y [expr round([winfo screenheight .]/2.0)]
                wm geometry $protocol -$x-$y
                wm resizable $protocol 0 0

                grid [ttk::frame $protocol.fp] -row 0 -column 0 -sticky news -padx 10 -pady 10

                set txt "Please specify a name for your custom protocol file: "
                grid [ttk::label $protocol.fp.txt -text $txt] -row 0 -column 0 -sticky ew -padx 2
                set values [file root $current]

                set QWIKMD::prtclSelected $index
                
                grid [ttk::combobox $protocol.fp.combovalues -values $values -textvariable QWIKMD::advGui(protocoltb,template)] -row 0 -column 0 -sticky ew  
                grid [ttk::label $protocol.fp.lbnames -text "NOTE: Don't use \".\" in the protocol name."] -row 1 -column 0 -sticky ew  
                grid [ttk::checkbutton $protocol.fp.checkTemplate -variable QWIKMD::advGui(protocoltb,$QWIKMD::run,$QWIKMD::prtclSelected,saveAsTemplate) -text "Save as template for future use" -command {
                    set values {Minimization Annealing Equilibration MD SMD QMMM-Min QMMM-Ann QMMM-Equi QMMM}
                    set tbnames [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 0]
                    set prtname [.protocol.fp.combovalues get]
                    set index $QWIKMD::prtclSelected
                    set protname [lindex [split $prtname "."] 0 ]
                    set newname ${protname}
                    if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,saveAsTemplate) == 1 && [lsearch $values $protname] != -1} {
                        ## *_edited is used to make sure uniqueness of the file names
                        set newname "${protname}_edited"
                        set QWIKMD::advGui(protocoltb,template) $newname
                        
                    } else {
                        set newname [regsub "_edited" ${protname} ""]
                        set QWIKMD::advGui(protocoltb,template) $newname
                    }   
                }] -row 2 -column 0 -sticky ew  
                
                grid [ttk::frame $protocol.fp.foOkcancel] -row 3 -column 0 -sticky news -padx 10 -pady 10
                grid [ttk::button $protocol.fp.foOkcancel.buttonok -text "Ok" -command {
                    destroy ".protocol"
                }] -row 0 -column 0 -sticky ew  

                grid [ttk::button $protocol.fp.foOkcancel.buttoncancel -text "Cancel" -command {
                    set QWIKMD::advGui(protocoltb,$QWIKMD::run,[$QWIKMD::advGui(protocoltb,$QWIKMD::run) curselection]) "Cancel"
                    destroy ".protocol"
                }] -row 0 -column 1 -sticky ew

                tkwait window $protocol
                if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$index) == "Cancel"} {
                    $QWIKMD::advGui(protocoltb,$QWIKMD::run) rejectinput
                    $QWIKMD::advGui(protocoltb,$QWIKMD::run) cancelediting
                    set prevprtcl [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $index,0 -text]
                    lset QWIKMD::confFile $index $prevprtcl
                    set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index) $prevprtcl
                    return
                } else {
                    lset QWIKMD::confFile $index $QWIKMD::advGui(protocoltb,template)
                }

                if {[file exists $env(QWIKMDFOLDER)/templates/$QWIKMD::advGui(solvent,$QWIKMD::run,0)/$QWIKMD::advGui(protocoltb,template).conf] ==1 && $QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,saveAsTemplate) == 1} {
                    set answer [tk_messageBox -message "$QWIKMD::advGui(protocoltb,template).conf protocol already exists. Do you want to replace?"\
                     -type yesnocancel -title "Protocol file" -icon info -parent $QWIKMD::topGui]
                    switch $answer {
                        yes {
                            continue
                        }
                        no {
                            QWIKMD::editProtocolProc
                        }
                        cancel {
                            return
                        }
                    }
                }
                
            }

            set args [$QWIKMD::advGui(protocoltb,$QWIKMD::run) rowcget $index -text]
            set outputfile $env(QWIKMDTMPDIR)/$QWIKMD::advGui(protocoltb,template).conf
            if {$newprotocolload == 1} {
                set outputfile $QWIKMD::advGui(protocoltb,template).conf
            }
            #set outputfile ${outputfile}.conf
            set location ""
            set template ${current}.conf
            set values {Minimization Annealing Equilibration MD SMD QMMM-Min QMMM-Ann QMMM-Equi QMMM}
            set serachindex [lsearch $values [file root $current] ]
            set location $env(QWIKMDFOLDER)/templates/
            if {$serachindex == -1 && [catch {glob ${location}$QWIKMD::advGui(solvent,$QWIKMD::run,0)/[file root $current].conf}] == 0} {
                append location $QWIKMD::advGui(solvent,$QWIKMD::run,0)
            } elseif {[catch {glob $env(QWIKMDTMPDIR)/[file root $current].conf}] == 0} {
                set location $env(QWIKMDTMPDIR)
            } elseif {$newprotocolload == 1} {
                set location ${QWIKMD::outPath}/run
                cd $location
            }
            set tempLib ""
            set do [catch {glob $location/*.conf} tempLib]
            ## Variable to check if the duplicated restart protocol has the template already edited in the QWIKMDTMPDIR
            set replicTemplateNotGenerated 0

            if {[file exists "$env(QWIKMDTMPDIR)/${current}.conf"] == 1 && $newprotocolload == 0} {
                set template $env(QWIKMDTMPDIR)/${current}.conf
            } elseif {$do == 0} {
                set tempAux ""
                foreach temp $tempLib {
                    set aux ""
                    lappend tempAux [file tail $temp]   
                }
                set current [file root [file tail $current]]
                set tmpIndex [lsearch [array get QWIKMD::advGui protocoltb,$QWIKMD::run,*] $current]
                if {$tmpIndex != -1} {
                    set tmpIndex [lindex [array get QWIKMD::advGui protocoltb,$QWIKMD::run,*] [expr $tmpIndex -1] ]
                } else {
                    return
                }
                if {[lsearch $tempAux ${current}.conf] == -1 || [file exists "$env(QWIKMDTMPDIR)/${current}.conf"] == 1 && $newprotocolload == 0} {
                    set template $env(QWIKMDTMPDIR)/${current}.conf
                } elseif {[file exists $env(QWIKMDTMPDIR)/${current}.conf] != 1 && [lindex [split $QWIKMD::advGui(protocoltb,$QWIKMD::run,$index) "."] 1] != "" \
                && $QWIKMD::advGui($tmpIndex,lock) == 0 && $newprotocolload == 0} {
                    set template "$location/${current}.conf"
                    if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,lock) == 1} {
                        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,lock) 0
                        set replicTemplateNotGenerated 1
                    }
                } else {    
                    set template $location/${current}.conf
                }
            } 
            if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,saveAsTemplate) == 1} {
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,lock) 0 
                #set replicTemplateNotGenerated 1
            }
            if {$QWIKMD::run == "SMD"} {
                if {[QWIKMD::isSMD "$template"] == 1} {
                    set conflist [list]
                    if {[llength $QWIKMD::prevconfFile] > 0} {
                        set conflist $QWIKMD::prevconfFile
                    } else {
                        set conflist $QWIKMD::confFile
                    }
                    set QWIKMD::advGui(protocoltb,$QWIKMD::run,[lsearch $conflist [file root $current]],smd) 1
                    set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,smd) 1 
                }
            } elseif {$QWIKMD::run == "QM/MM"} {
                if {[QWIKMD::isQMMM "$template"] == 1} {
                    set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,qmmm) 1 
                }
            }
            set psfpdb "qwikmdTemp.psf qwikmdTemp.pdb"
            ## Get PSF and PDB file initial structure of the simulation
            if {$newprotocolload == 1} {
                set aux [molinfo $QWIKMD::topMol get name]
                set aux [file rootname $aux]
                set psfpdb "${aux}.psf ${aux}.pdb"
            }
            QWIKMD::GenerateNamdFiles $psfpdb "$template" $index $args "$outputfile"

            ## Delete previous check proc for the correct termination of namd simulation in the end of the conf file
            if {$newprotocolload == 1} {
                set outputfile $QWIKMD::advGui(protocoltb,template).conf
                set conffile [open ${outputfile} r]
                set tempfile [open ${env(QWIKMDTMPDIR)}/temp.conf w+]
                set line  ""
                while {[eof $conffile] != 1} {
                    ## is this the first line of the check section?
                    set line [gets $conffile]
                    if {[regexp {set file \[open .+.check w+} $line] == 1} {
                        break
                    }
                    puts $tempfile $line
                }
                close $conffile
                close $tempfile
                file copy -force ${env(QWIKMDTMPDIR)}/temp.conf ${outputfile}
                QWIKMD::addNAMDCheck $index
            }
            set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,lock) 0
            set instancehandle [multitext -justsave]
            $instancehandle openfile "$outputfile"
            set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index) $QWIKMD::advGui(protocoltb,template)
            $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $index,0 -text $QWIKMD::advGui(protocoltb,template)
            QWIKMD::lockUnlockProc $index
        } else {
            cd ${QWIKMD::outPath}/run
            set instancehandle [multitext -justsave]
            set file [lindex $QWIKMD::confFile $index]
            $instancehandle openfile "${file}.conf"
        }
        
    }
}
######################################################
## Add velocity and distance widgets for SMD protocol
######################################################
proc QWIKMD::addSMDVD {frame row col} {
    set QWIKMD::basicGui(plength) 10.0
    grid [ttk::label $frame.ltime -text "Pulling Distance" -justify center] -row $row -column $col -sticky ew 
    grid [ttk::entry $frame.entryLength -width 7 -justify right -textvariable QWIKMD::basicGui(plength) -validate focus -validatecommand {QWIKMD::reviewLenVelTime 1}] -row $row -column [expr $col +1] -sticky ew 
    grid [ttk::label $frame.lns -text "A"] -row $row -column [expr $col + 2] -sticky ew 

    QWIKMD::balloon $frame.ltime [QWIKMD::smdMaxLengthBL]
    QWIKMD::balloon $frame.entryLength [QWIKMD::smdMaxLengthBL]
    incr row
    set QWIKMD::basicGui(pspeed) 2.5
    grid [ttk::label $frame.lvel -text "Pulling Speed" -justify center] -row $row -column $col -sticky ew 
    grid [ttk::entry $frame.entryvel -width 7 -justify right -textvariable QWIKMD::basicGui(pspeed) -validate focus -validatecommand {QWIKMD::reviewLenVelTime 2}] -row $row -column [expr $col +1] -sticky ew 
    grid [ttk::label $frame.lvelUnit -text "A/ns" ] -row $row -column [expr $col + 2] -sticky ew 

    QWIKMD::balloon $frame.lvel [QWIKMD::smdVelocityBL]
    QWIKMD::balloon $frame.entryvel [QWIKMD::smdVelocityBL]
    
    set QWIKMD::basicGui(mdtime,1) [expr $QWIKMD::basicGui(plength) / $QWIKMD::basicGui(pspeed)]

    
}
######################################################
## Add pulling and anchor residues selection buttons
######################################################
proc QWIKMD::addSMDAP {frame row col} {

    grid [ttk::button $frame.pulBut -text "Pulling Residues" -padding "2 0 2 0" -width 15 -command {
        set QWIKMD::anchorpulling 1
        set QWIKMD::selResidSel $QWIKMD::pullingRessel
        QWIKMD::selResidForSelection "Select Pulling Residues" $QWIKMD::pullingRes
        set QWIKMD::buttanchor 2
        set QWIKMD::showpull 1
        QWIKMD::checkAnchors
    }] -row $row -column $col -sticky e -padx 2

    QWIKMD::balloon $frame.pulBut [QWIKMD::smdPullingBL]
    grid [ttk::checkbutton $frame.showpulling -text "Show" -variable QWIKMD::showpull -command {QWIKMD::checkAnchors}] -row $row -column [expr $col +1] -sticky e -padx 4
    incr row
    
    set QWIKMD::showpull 0
    grid [ttk::button $frame.anchorBut -text "Anchoring Residues " -padding "2 0 2 0" -width 15 -command {
        set QWIKMD::anchorpulling 1
        set QWIKMD::selResidSel $QWIKMD::anchorRessel
        QWIKMD::selResidForSelection "Select Anchoring Residues" $QWIKMD::anchorRes
        set QWIKMD::buttanchor 1
        set QWIKMD::showanchor 1
        QWIKMD::checkAnchors
    }] -row $row -column $col -sticky e -padx 2

    QWIKMD::balloon $frame.anchorBut [QWIKMD::smdAnchorBL]
    grid [ttk::checkbutton $frame.showanchor -text "Show" -variable QWIKMD::showanchor -command {QWIKMD::checkAnchors}] -row $row -column [expr $col + 1] -sticky e -padx 4
    set QWIKMD::showanchor 0
    
}
#####################################################
## Add protocol entries to the protocol tables
#####################################################
proc QWIKMD::addProtocol {} {
    global env
    set index [$QWIKMD::advGui(protocoltb,$QWIKMD::run) curselection]
    set tbnames [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 0]
    set str ""
    set blocktemp 0
    set blockpress 0
    set ensemble "NpT"
    set lock_previous 0
    if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Implicit" || $QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Vacuum"} {
        set ensemble "NVT"
        set blockpress 1
    } 
    ## if index == "" means that is not a replication / continuation of a previous protocol 
    if {$index == ""} {
    
        set name $QWIKMD::run
        if {$QWIKMD::run == "QM/MM"} {
            if {[llength $tbnames] > 2} {
                set name "QMMM"
            }
            
        }
        set steps 500000
        set temperature 27
        set restraints "none"
        set press 1
        if {$QWIKMD::run != "QM/MM"} {
            if {[llength $tbnames] == 0} {
                set name "Minimization"
                set restraints "backbone"
                set temperature 0
                set steps 2000
            } elseif {[llength $tbnames] == 1} {
                set name "Annealing"
                set restraints "backbone"
                set temperature 27
                set steps 144000
            } elseif {[llength $tbnames] == 2} {
                set name "Equilibration"
                set restraints "backbone"
                set temperature 27
                set steps 500000
            } 
        } else {
            if {[llength $tbnames] == 0} {
                set name "QMMM-Min"
                set restraints "backbone"
                set temperature 0
                set steps 100
            } elseif {[llength $tbnames] == 1} {
                set name "QMMM-Ann"
                set restraints "backbone"
                set temperature 27
                set steps 720
            } elseif {[llength $tbnames] == 2} {
                set name "QMMM-Equi"
                set restraints "backbone"
                set temperature 27
                set steps 100
            } 
        }       

        set i 1
        set add 0
        set previndex -1
        while {[lsearch $tbnames $name] != -1} {
            set previndex [lsearch $tbnames $name]
            set name "[file root $name].$i"
            set add 1
            incr i
        }
        
        if {$add == 1 && $i == 2} {
            set lock_previous 1
        }
        if {$add == 1} {
            #set name [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $previndex,0 -text]
            set steps [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $previndex,1 -text]
            set restraints [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $previndex,2 -text]
            set temperature [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $previndex,4 -text]
            set press [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $previndex,5 -text]
        }

        set str [list $name $steps $restraints $ensemble $temperature $press]
        
    } else {
        set name [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $index,0 -text]
        # set toRemove {Minimization Annealing Equilibration}
        # if {[lsearch $toRemove $name] > -1} {
        #     tk_messageBox -message "Only one $name protocol is allowed." -title "Protocol Replication" -icon warning -type ok
        #     return
        # }

        set i 1
        set add 0
        while {[lsearch $tbnames $name] != -1} {
            set name "[file root $name].$i"
            set add 1
            incr i
        }

        if {$add == 1 && $i == 2} {
            set lock_previous 1
        }
        set nstep [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $index,1 -text]
        set restraints [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $index,2 -text]
        set ensemble [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $index,3 -text]
        set temp [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $index,4 -text]
        set press [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $index,5 -text]
        set row [$QWIKMD::advGui(protocoltb,$QWIKMD::run) rowcget $index -text]

        set str  [list $name $nstep $restraints $ensemble $temp $press]

    }
    if {$str != ""} {
        
        array set auxArr [list]
        set tblsize [$QWIKMD::advGui(protocoltb,$QWIKMD::run) size]
        set line $tblsize
        if {$index != "" && $index != [expr $tblsize -1] && $tblsize != 0} {
            set lastindex 0
            foreach name $tbnames {
                if {[file root [lindex $str 0] ] == [file root $name]} {
                    incr lastindex
                }
                
            }
            set lastindex [expr  [lsearch $tbnames "[file root [lindex $str 0] ]"] + $lastindex]
            set line $lastindex
            array set auxArr [array get QWIKMD::advGui protocoltb,*]
            set j 0
            for {set i 0} {$i < $tblsize} {incr i} {
                if {$i == $line } {
                    incr j
                }   
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j,lock) $auxArr(protocoltb,$QWIKMD::run,$i,lock)
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j,saveAsTemplate) $auxArr(protocoltb,$QWIKMD::run,$i,saveAsTemplate)
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j) $auxArr(protocoltb,$QWIKMD::run,$i)
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j,restrIndex) $auxArr(protocoltb,$QWIKMD::run,$i,restrIndex)
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j,restrsel) $auxArr(protocoltb,$QWIKMD::run,$i,restrsel)
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j,smd) $auxArr(protocoltb,$QWIKMD::run,$i,smd)
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j,qmmm) $auxArr(protocoltb,$QWIKMD::run,$i,qmmm)
                incr j
            }   
        }
        
        $QWIKMD::advGui(protocoltb,$QWIKMD::run) insert $line $str
        if {$blockpress == 1} {
            $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $line,5 -editable false  
        }

        if {$blocktemp == 1} {
            $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $line,4 -editable false  
        }
        set index $line
        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,lock) 1
        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,saveAsTemplate) 0
        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index) [lindex $str 0]
        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,restrIndex) [list]
        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,restrsel) ""
        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,smd) 0
        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,qmmm) 0
        QWIKMD::checkProc $index
        if {$lock_previous == 1} {
            $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure [expr $index - 1],0 -editable false  
        }
    }

}
###############################################
## Delete protocol entries and update 
## the QWIKMD::advGui(protocoltb,...) array 
##############################################
proc QWIKMD::deleteProtocol {} {
    set index [$QWIKMD::advGui(protocoltb,$QWIKMD::run) curselection]
    if {$index != ""} {

        array set auxArr [list]
        set tblsize [$QWIKMD::advGui(protocoltb,$QWIKMD::run) size]
        if {$index != "" && $index != [expr [$QWIKMD::advGui(protocoltb,$QWIKMD::run) size] -1]} {
            
            array set auxArr [array get QWIKMD::advGui protocoltb,$QWIKMD::run*]
            set j 0
            for {set i 0} {$i < $tblsize} {incr i} {
                if {$i == $index} {
                    incr i
                }   
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j,lock) $auxArr(protocoltb,$QWIKMD::run,$i,lock)
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j,saveAsTemplate) $auxArr(protocoltb,$QWIKMD::run,$i,saveAsTemplate)
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j) $auxArr(protocoltb,$QWIKMD::run,$i)
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j,restrIndex) $auxArr(protocoltb,$QWIKMD::run,$i,restrIndex)
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j,restrsel) $auxArr(protocoltb,$QWIKMD::run,$i,restrsel)
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j,smd) $auxArr(protocoltb,$QWIKMD::run,$i,smd)
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$j,qmmm) $auxArr(protocoltb,$QWIKMD::run,$i,qmmm)
                # if {$QWIKMD::run == "SMD"} {
                    
                # }
                incr j
            }   
            array unset QWIKMD::advGui protocoltb,$QWIKMD::run,[expr $tblsize -1],*
            array unset QWIKMD::advGui protocoltb,$QWIKMD::run,[expr $tblsize -1]
            array unset auxArr *
        } elseif {$tblsize == 1} {
            array unset QWIKMD::advGui protocoltb,$QWIKMD::run,*
        } else {
            array unset QWIKMD::advGui protocoltb,$QWIKMD::run,$index,*
            array unset QWIKMD::advGui protocoltb,$QWIKMD::run,$index
        }
        
        $QWIKMD::advGui(protocoltb,$QWIKMD::run) delete $index
        if {[$QWIKMD::advGui(protocoltb,$QWIKMD::run) size] > 0} {
            QWIKMD::checkProc 0
        }
        if {[expr $index -1] > -1} {
            $QWIKMD::advGui(protocoltb,$QWIKMD::run) selection set [expr $index -1]
        }
    }
}
###########################################################
## proc triggered by editing a cell of the protocol table 
###########################################################
proc QWIKMD::cellStartEditPtcl {tbl row col text} {
    global env
    set w [$tbl editwinpath]
    
    switch [$tbl columncget $col -name] {
        Protocol {
            
            set values {Minimization Annealing Equilibration MD SMD QMMM-Min QMMM-Ann QMMM-Equi QMMM}

            set tempLib ""
            set do [catch {glob ${env(QWIKMDFOLDER)}/templates/$QWIKMD::advGui(solvent,$QWIKMD::run,0)/*.conf} tempLib]
            set tbvalues [$tbl getcolumns $col]
            if {$do == 0} {
                set tempAux ""
                foreach temp $tempLib {
                    set aux ""
                    regsub -all ".conf" [file tail $temp ] "" aux
                    if {[lsearch $values $aux] == -1 && [lsearch $tbvalues $aux] == -1} {
                        lappend values $aux
                    }
                    
                }
            }
            

            if {$QWIKMD::run != "SMD"} {
                set index [lsearch $values "SMD"]
                set values [lreplace $values $index $index]
            }
            
            if {$QWIKMD::run != "QM/MM"} {
                set index [lsearch -regexp $values (?i)^QMMM]
                while {$index > -1} {
                    set values [lreplace $values $index $index]
                    set index [lsearch -regexp $values (?i)^QMMM]
                }
            } else {
                set index [lsearch -regexp -not $values (?i)^QMMM]
                while {$index > -1} {
                    set values [lreplace $values $index $index]
                    set index [lsearch -regexp -not $values (?i)^QMMM]
                }
            }
            set toRemove {Minimization Annealing Equilibration MD}

            for {set i 0} {$i < [llength $tbvalues]} {incr i} {

                set index [lsearch -all $toRemove [lindex $tbvalues $i] ]
                if {$index > -1} {
                    set valind [lsearch $values [lindex $toRemove $index]]
                    set values [lreplace $values $valind $valind]
                }
                set tbvalues [$tbl getcolumns $col]
            }
            $w configure -values $values -state readonly -style protocol.TCombobox -takefocus 0 -exportselection false -justify center
            bind $w <<ComboboxSelected>> {
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) finishediting  
            }

        }
        nSteps {
            set from 10
            set to 500000000000
            set incrm 10
            if {[regexp "QMMM*" [$tbl cellcget $row,0 -text]] != 0} {
                set incrm 1
            }
            $w configure -from $from -to $to -increment $incrm

        }
        Restraints {
            set values {none backbone "alpha carbon" protein "protein and not hydrogen" "From List"}
            $w configure -width 20 -values $values -state normal -style protocol.TCombobox
            bind $w <<ComboboxSelected>> {
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) finishediting  
            }
        }
        Ensemble {
            set values {NpT NVT NVE}
            if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Implicit" || $QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Vacuum"} {
                set values {NVT NVE}    
            }
            $w configure -values $values -state readonly -style protocol.TCombobox
            bind $w <<ComboboxSelected>> {
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) finishediting  
            }
        }
        Temp {
            set from 0
            set to 1000
            $w configure -from $from -to $to -increment 0.5
        }
        Pressure {
            set from 0.0
            set to 200
            $w configure -from $from -to $to -increment 0.1
        }
    }
    return $text
}

proc QWIKMD::cellEndEditPtcl {tbl row col text} {
    
    global env
    set w [$tbl editwinpath]

    switch [$tbl columncget $col -name] {
        Protocol {

            set values {Minimization Annealing Equilibration MD SMD QMMM-Min QMMM-Ann QMMM-Equi QMMM}
            set tempLib ""
            set index [lsearch $values $text]
            
            if {$index == -1} {
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$row,lock) 0
            } else {
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$row,lock) 1
            }
            QWIKMD::lockUnlockProc $row
            # if {$text == "Equilibration" || $text == "Minimization" || $text == "Annealing"} {
            #   $tbl cellconfigure $row,2 -text "backbone"
            #   if {$text == "Annealing"} {
            #       $tbl cellconfigure $row,1 -text 144000
            #   } elseif {$text == "Equilibration"} {
            #       $tbl cellconfigure $row,1 -text 500000
            #   } else {
            #       $tbl cellconfigure $row,1 -text 2000
            #   }
            # } else {
            #   $tbl cellconfigure $row,2 -text "none"
            # }
            if {$text == ""} {set text $QWIKMD::run}
            set QWIKMD::advGui(protocoltb,$QWIKMD::run,$row) $text
        }
        nSteps {
            set val $text
            set increm 10
            if {[$tbl cellcget $row,0 -text] == "Annealing"} {
                set temp [expr [$tbl cellcget $row,4 -text] + 213.0]
                set annealval [expr $text / $temp ]
                set textaux $annealval
                if {[expr fmod($annealval,10)] > 0} {
                    set textaux [expr int($annealval + [expr 10 - [expr fmod($annealval,10)]])]
                    set text [expr int($textaux * $temp)]
                }
                set val $textaux 
            } elseif {[regexp "QMMM*" [$tbl cellcget $row,0 -text]] != 0} {
                set increm 1
                if {[$tbl cellcget $row,0 -text] == "QMMM-Ann"} {
                    set temp [expr [$tbl cellcget $row,4 -text] + 213.0]
                    set annealval [expr $text / $temp ]
                    set textaux $annealval
                    if {[expr fmod($annealval,$increm)] > 0} {
                        set textaux [expr int($annealval + [expr $increm - [expr fmod($annealval,$increm)]])]
                        set text [expr int($textaux * $temp)]
                    }
                    set val $textaux 
                }
            }
        
            if {($val <= 0 || [expr fmod($val,$increm)] > 0)} {
                tk_messageBox -message "Number of steps must be positive and multiple of $increm." \
                -icon warning -type ok -parent $QWIKMD::topGui
                $tbl rejectinput
            } else {
                lset QWIKMD::maxSteps $row $text
            }
        }
        Restraints {
            if {[molinfo num] == 0 } {
                tk_messageBox -message "No molecule loaded" -title "No Molecule" -icon warning\
                 -type ok -parent $QWIKMD::topGui
                return [$tbl cellcget $row,$col -text]
            }
            if {$text == ""} {set text "none"}
            if {$text != "none"} {
                if {$text == "From List"} {
                    set QWIKMD::anchorpulling 0
                    set QWIKMD::buttanchor 0
                    if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$row,restrsel) == ""} {
                        set QWIKMD::selResidSel "Type Selection"
                    } else {
                        set QWIKMD::selResidSel $QWIKMD::advGui(protocoltb,$QWIKMD::run,$row,restrsel)
                        set QWIKMD::selResidSelIndex $QWIKMD::advGui(protocoltb,$QWIKMD::run,$row,restrIndex)
                    }   
                    QWIKMD::selResidForSelection "Restraints Selection" $QWIKMD::advGui(protocoltb,$QWIKMD::run,$row,restrIndex)
                    $tbl rejectinput
                } else {
                    set sel ""
                    set length [expr [array size QWIKMD::chains] /3]
                    set seltxt ""
                    for {set i 0} {$i < $length} {incr i} {
                        if {$QWIKMD::chains($i,0) == 1} {
                            append seltxt " ([lindex $QWIKMD::index_cmb($QWIKMD::chains($i,1),5)]) or"  
                        }
                        
                    }
                    set seltextaux $text
                    if {$text == "protein and not hydrogen"} {
                        set seltextaux "protein and noh"
                    }
                    set seltxt [string trimleft $seltxt " "]
                    set seltxt [string trimright $seltxt " or"]
                    set seltxt "($seltxt) and $seltextaux"
                    set do [catch {atomselect $QWIKMD::topMol $seltxt} sel]
                    
                    if {$do == 1} {
                        set ind ""
                    } else {
                        set ind [$sel get index]
                    }
                    $sel delete
                    if {$ind == ""} {
                        tk_messageBox -message "Invalid atom selection." -icon warning -type ok -parent $QWIKMD::topGui
                        $tbl rejectinput
                    }
                }   
            }
        }
        Ensemble {
            if {$text == "NVE"} {
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $row,4 -editable false
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $row,5 -editable false
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $row,4 -foreground grey -selectforeground grey
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $row,5 -foreground grey -selectforeground grey
            } elseif {$text == "NVT"  && $QWIKMD::advGui(protocoltb,$QWIKMD::run,$row,lock) == 0} {
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $row,4 -editable true
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $row,5 -editable false
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $row,4 -foreground black -selectforeground black
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $row,5 -foreground grey -selectforeground grey
            } elseif {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$row,lock) == 0} {
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $row,4 -editable true
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $row,5 -editable true
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $row,4 -foreground black -selectforeground black
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $row,5 -foreground black -selectforeground black
            }
        }
        Temp {
            if {$text > 100} {
                tk_messageBox -message "Temperature too high. Please note that temperature is Celsius and not Kelvin."\
                 -icon warning -type ok -parent $QWIKMD::topGui
                
            } elseif {$text == ""} {
                set text 27
            }
        }
        Pressure {
            if {$text < 0 || $text == ""} {
                set text 1
            } 
        }
    }
    return $text
}
##############################################
## Add new QM region to the QM region table
##############################################
proc QWIKMD::addQMregion {} {
    global env
    # set index [$QWIKMD::advGui(qmtable) curselection]
    set tbnames [$QWIKMD::advGui(qmtable) getcolumns 0]
    set str ""
    
    set qmID [expr [llength $tbnames] +1]
    set qmRegion "0"
    set charge 0
    set multi 1
    set com "none"

    set str [list $qmID $qmRegion $charge $multi $com]

    $QWIKMD::advGui(qmtable) insert end $str

    set QWIKMD::advGui(qmtable,$qmID,qmRegionSel) "Type Selection"
    set QWIKMD::advGui(qmtable,$qmID,qmRegionSelIndex) [list]
    set QWIKMD::advGui(qmtable,$qmID,qmPtChargesNumAtoms) 0
    set QWIKMD::advGui(qmtable,$qmID,qmTopoCharge) 0
    set QWIKMD::advGui(qmtable,$qmID,qmCOMSel) ""
    set QWIKMD::advGui(qmtable,$qmID,qmCOMIndex) [list]
    set QWIKMD::advGui(qmtable,$qmID,charge) 0
    set QWIKMD::advGui(qmtable,$qmID,multi) 1
    set QWIKMD::advGui(qmtable,$qmID,com) "none"
    set QWIKMD::advGui(qmtable,$qmID,pcDist) 10
    set QWIKMD::advGui(qmtable,$qmID,solvDist) 10
    set QWIKMD::advGui(qmtable,tbselected) 0
    
}
####################################################
## Delete QM region from the QM region table
## and update the QWIKMD::advGui(qmtable,...) array
####################################################
proc QWIKMD::deleteQMregion {} {
    set index [$QWIKMD::advGui(qmtable) curselection]
    if {$index != ""} {
        array set auxArr [list]
        set tblsize [$QWIKMD::advGui(qmtable) size]
        if {$index != "" && $index != [expr [$QWIKMD::advGui(qmtable) size] -1]} {
            array set auxArr [array get QWIKMD::advGui qmtable,*]
            set j 1
            for {set i 1} {$i <= $tblsize} {incr i} {
                if {$i == [expr $index + 1]} {
                    incr i
                }
                #set QWIKMD::advGui(qmtable,$j,qmRegionNumAtoms) $auxArr(qmtable,$i,qmRegionNumAtoms)
                set QWIKMD::advGui(qmtable,$j,qmRegionSel) $auxArr(qmtable,$i,qmRegionSel)
                set QWIKMD::advGui(qmtable,$j,qmRegionSelIndex) $auxArr(qmtable,$i,qmRegionSelIndex)
                set QWIKMD::advGui(qmtable,$j,charge) $auxArr(qmtable,$i,charge)
                set QWIKMD::advGui(qmtable,$j,multi) $auxArr(qmtable,$i,multi)
                set QWIKMD::advGui(qmtable,$j,com) $auxArr(qmtable,$i,com)
                set QWIKMD::advGui(qmtable,$j,pcDist) $auxArr(qmtable,$i,pcDist)
                set QWIKMD::advGui(qmtable,$j,solvDist) $auxArr(qmtable,$i,solvDist)

                set QWIKMD::advGui(qmtable,$j,qmPtChargesNumAtoms) $auxArr(qmtable,$i,qmPtChargesNumAtoms)
                set QWIKMD::advGui(qmtable,$j,qmCOMSel) $auxArr(qmtable,$i,qmCOMSel)
                set QWIKMD::advGui(qmtable,$j,qmCOMIndex) $auxArr(qmtable,$i,qmCOMIndex)
                set QWIKMD::advGui(qmtable,$j,qmTopoCharge) $auxArr(qmtable,$i,qmTopoCharge)
                $QWIKMD::advGui(qmtable) cellconfigure $j,0 -text $j
                incr j
            }   
            array unset QWIKMD::advGui qmtable,$tblsize,*
            array unset QWIKMD::advGui qmtable,$tblsize
            array unset auxArr *
        } elseif {$tblsize == 1} {
            array unset QWIKMD::advGui qmtable,*
        } else {
            array unset QWIKMD::advGui qmtable,[expr $index + 1],*
            array unset QWIKMD::advGui qmtable,[expr $index + 1]
        }
        
        $QWIKMD::advGui(qmtable) delete $index
        if {[expr $index -1] > -1} {
            $QWIKMD::advGui(qmtable) selection set [expr $index -1]
        }
    }
}
###################################################
## proc triggered by edit cell of QM regions table 
###################################################
proc QWIKMD::cellStartEditQMReg {tbl row col text} {
    global env
    set w [$tbl editwinpath]
    if {[$tbl columncget $col -name] == "Mult"} {
        $w configure -state normal -values {0 1} 
        bind $w <<ComboboxSelected>> {
            $QWIKMD::advGui(qmtable) finishediting  
        } 
    }
    return $text
}

proc QWIKMD::cellEndEditQMReg {tbl row col text} {
    global env
    set qmID [expr $row + 1] 
    switch [$tbl columncget $col -name] {
        Charge {
            set sel [atomselect $QWIKMD::topMol "segname ION"]
            set num [$sel num]
            $sel delete
            if {$num == 0 && $QWIKMD::advGui(qmtable,$qmID,charge) != "[expr round($text)].00"} {
                tk_messageBox -message "To select a QM charge different than the charge selected during the preparation \
                phase, the system needs to be prepared with solvent ions." -title "QM Region Charge" -type ok -icon warning\
                -parent $QWIKMD::topGui
                return $QWIKMD::advGui(qmtable,$qmID,charge)
            }
            set numqm [$tbl size]
            set QWIKMD::advGui(qmtable,$qmID,charge) "[expr round($text)].00"
            set total_differ 0
            for {set i 1} {$i <= $numqm} {incr i} {
                if {$QWIKMD::advGui(qmtable,$i,qmRegionSel) != "Type Selection"} {
                    set total_differ [expr $total_differ + [expr $QWIKMD::advGui(qmtable,$i,charge) - $QWIKMD::advGui(qmtable,$i,qmTopoCharge) ] ]
                }
            }
            set ions $QWIKMD::advGui(saltions,$QWIKMD::run,0)
            set atomname ""
            set sign +
            set replaced ""
            if {$total_differ < 0} {
                set replaced "SOD"
                if {$ions == "KCl"} {
                    set replaced "POT"
                }
                set atomname "CLA"
            } elseif {$total_differ > 0} {
                set replaced "CLA"
                set atomname "SOD"
                if {$ions == "KCl"} {
                    set atomname "POT"
                }
                set sign -
            } else {
                return $text
            }

            set sel [atomselect $QWIKMD::topMol "name $atomname"]
            set num [expr [$sel num] *2]
            $sel delete
            if {[expr abs($total_differ)] > $num} {
                tk_messageBox -message "There is only ${sign}$num possible additional charges ([expr $num /2] $atomname atoms * 2) \
                to compensate a total charge difference of $total_differ. $replaced are replaced by $atomname \
                to add or reduce two charges. The charge of $replaced atoms can also be changed to 0 \
                if the difference in charges is 1. Please select a different charge"\
                 -title "QM Region Charge" -type ok -icon warning -parent $QWIKMD::topGui
                set QWIKMD::advGui(qmtable,$qmID,charge) $QWIKMD::advGui(qmtable,$qmID,qmTopoCharge)
                 
            }  
            set text $QWIKMD::advGui(qmtable,$qmID,charge)  
        }
        Mult {
            set QWIKMD::advGui(qmtable,$qmID,multi) $text 
        }
    }
    return $text
}
#############################
## Build basic analysis tab 
#############################
proc QWIKMD::BasicAnalyzeFrame {frame} {
    
    grid [ttk::frame $frame.fp ] -row 0 -column 0 -sticky nsew -pady 2 -padx 2 
    grid columnconfigure $frame.fp 0 -weight 1
    
    set row 0
    grid rowconfigure $frame.fp $row -weight 0
    grid [ttk::frame $frame.fp.rmsd -relief groove] -row $row -column 0 -sticky nsew -pady 2 -padx 2 
    grid columnconfigure $frame.fp.rmsd 0 -weight 1

    QWIKMD::RMSDFrame $frame.fp.rmsd

    incr row
    grid rowconfigure $frame.fp $row -weight 0

    grid [ttk::frame $frame.fp.energies -relief groove] -row $row -column 0 -sticky nsew -pady 4 -padx 2 
    grid columnconfigure $frame.fp.energies 0 -weight 1

    QWIKMD::EnerFrame $frame.fp.energies

    incr row
    grid rowconfigure $frame.fp $row -weight 0
    grid [ttk::frame $frame.fp.thermo -relief groove] -row $row -column 0 -sticky nsew -pady 4 -padx 2 
    grid columnconfigure $frame.fp.thermo 0 -weight 1

    QWIKMD::ThermoFrame $frame.fp.thermo

    incr row
    grid rowconfigure $frame.fp $row -weight 2
    grid [ttk::frame $frame.fp.plot ] -row $row -column 0 -sticky nsew -pady 4 -padx 2 
    grid columnconfigure $frame.fp.plot 0 -weight 1

    QWIKMD::plotframe $frame.fp.plot basic

}
#############################
## Build RMSD frame tab 
#############################
proc QWIKMD::RMSDFrame {frame} {

    grid [ttk::frame $frame.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header 0 -weight 1
    grid [ttk::label $frame.header.lbtitle -text "$QWIKMD::rightPoint RMSD" -width 15] -row 0 -column 0 -sticky nw -pady 2 -padx 2

    bind $frame.header.lbtitle <Button-1> {
        QWIKMD::hideFrame %W [lindex [grid info %W] 1] "RMSD"
    }
    grid [ttk::frame $frame.header.fcolapse ] -row 1 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header.fcolapse 0 -weight 1

    grid [ttk::button $frame.header.fcolapse.rmsdRun -text "Calculate" -padding "2 2 2 2" -width 15 -command {
         ## Calculate RMSD and build the plot
         if {$QWIKMD::rmsdGui == ""} {
            #set plot 1
            set xlab "Time (ns)"
            if {$QWIKMD::run == "QM/MM"} {
                set xlab "Time (ps)"
            }
            set info [QWIKMD::addplot frmsd "RMSD Plot" "Rmsd vs Time" $xlab "Rmsd (A)"]
            set QWIKMD::rmsdGui [lindex $info 0]

            set clear [lindex $info 1]
            set close [lindex $info 2]
            
            $clear entryconfigure 0 -command {
                $QWIKMD::rmsdGui clear
                set QWIKMD::timeXrmsd 0
                set QWIKMD::rmsd 0
                $QWIKMD::rmsdGui add 0 0
                $QWIKMD::rmsdGui replot
            }

            $close entryconfigure 0 -command {
                $QWIKMD::rmsdGui quit
                destroy $QWIKMD::advGui(analyze,basic,ntb).frmsd
                set QWIKMD::rmsdGui ""
                set QWIKMD::rmsdplotview 0
            }
            set QWIKMD::rmsdplotview 1

        } else {
            $QWIKMD::rmsdGui clear
            set QWIKMD::timeXrmsd 0
            set QWIKMD::rmsd 0
            $QWIKMD::rmsdGui add 0 0
            $QWIKMD::rmsdGui replot
            set QWIKMD::rmsdplotview 1
        } 

        if {$QWIKMD::load == 1} {

            set numframes [molinfo $QWIKMD::topMol get numframes]
            set seltext ""
            if {$QWIKMD::advGui(analyze,basic,selentry) != "" && $QWIKMD::advGui(analyze,basic,selentry) != "Type Selection"} {
                set seltext $QWIKMD::advGui(analyze,basic,selentry)
            } else {
                set seltext $QWIKMD::advGui(analyze,basic,selcombo)
            }
            set sel_ref [atomselect $QWIKMD::topMol $seltext frame 0]
            set sel [atomselect $QWIKMD::topMol $seltext]
            set j 0
            set do 1
            set const 2e-6
            set increment [expr $const * [expr $QWIKMD::dcdfreq * $QWIKMD::loadstride] ]
            for {set i 1} {$i < $numframes} {incr i} {

                if {$i < [lindex $QWIKMD::lastframe $j]} {
                    if {$do == 1} {
                        set logfile [open [lindex $QWIKMD::confFile $j].log r]
                        while {[eof $logfile] != 1 } {
                            set line [gets $logfile]

                            if {[lindex $line 0] == "Info:" && [lindex $line 1] == "TIMESTEP"} {
                                set const [expr [lindex $line 2] * 1e-6]
                                if {$QWIKMD::run == "QM/MM"} {
                                    set const [expr $const * 1e3]
                                }
                            }

                            if {[lindex $line 0] == "Info:" && [join [lrange $line 1 2]] == "DCD FREQUENCY" } {
                                set QWIKMD::dcdfreq [lindex $line 3]
                                break
                            }
                        }
                        close $logfile
                        set do 0
                        set increment [expr $const * [expr $QWIKMD::dcdfreq * $QWIKMD::loadstride] ]
                    }   
                } else {
                    incr j
                    set do 1
                }
                $sel frame $i
                set xtime [expr [lindex $QWIKMD::timeXrmsd end] + $increment]
                lappend QWIKMD::timeXrmsd $xtime
                lappend QWIKMD::rmsd [QWIKMD::rmsdAlignCalc $sel $sel_ref $i]
            }
            $QWIKMD::rmsdGui clear
            $QWIKMD::rmsdGui add $QWIKMD::timeXrmsd $QWIKMD::rmsd
            $QWIKMD::rmsdGui replot
            set QWIKMD::rmsdprevx [lindex $QWIKMD::timeXrmsd end]

            puts $QWIKMD::textLogfile [QWIKMD::printRMSD $numframes $seltext $const]
            flush $QWIKMD::textLogfile
        } else {
            QWIKMD::RmsdCalc
        }

    } ] -row 0 -column 0 -sticky ens -pady 2 -padx 1

    QWIKMD::balloon $frame.header.fcolapse.rmsdRun [QWIKMD::rmsdCalcBL]

    QWIKMD::createInfoButton $frame.header 0 0
    bind $frame.header.info <Button-1> {
        set val [QWIKMD::rmsdInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow rmsdInfo [lindex $val 0] [lindex $val 2]
    }

    grid [ttk::frame $frame.header.fcolapse.selection ] -row 1 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header.fcolapse.selection 0 -weight 0
    grid columnconfigure $frame.header.fcolapse.selection 1 -weight 0
    grid columnconfigure $frame.header.fcolapse.selection 2 -weight 2
    

    set values {"Backbone" "Alpha Carbon" "No Hydrogen" "All"}
    grid [ttk::combobox $frame.header.fcolapse.selection.combo -values $values -width 12 -state readonly  -exportselection 0] -row 0 -column 0 -sticky nsw -padx 2
    grid [ttk::label $frame.header.fcolapse.selection.lbor -text "or"] -row 0 -column 1 -sticky w -padx 5
    
    $frame.header.fcolapse.selection.combo set "Backbone"
    set QWIKMD::advGui(analyze,basic,selcombo) "backbone"
    bind $frame.header.fcolapse.selection.combo <<ComboboxSelected>> {
        set text [%W get]
        switch  $text {
            Backbone {
                set QWIKMD::advGui(analyze,basic,selcombo) "backbone"
            }
            "Alpha Carbon" {
                set QWIKMD::advGui(analyze,basic,selcombo) "alpha carbon"
            }
            "No Hydrogen" {
                set QWIKMD::advGui(analyze,basic,selcombo) "noh"
            }
            "All" {
                set QWIKMD::advGui(analyze,basic,selcombo) "all"
            }
            
        }
        %W selection clear
    }
    ttk::style configure RmsdSel.TEntry -foreground $QWIKMD::tempEntry

    QWIKMD::balloon $frame.header.fcolapse.selection.combo [QWIKMD::rmsdSelection]

    grid [ttk::entry $frame.header.fcolapse.selection.entry -style RmsdSel.TEntry -textvariable QWIKMD::advGui(analyze,basic,selentry) -validate focus -validatecommand {
        QWIKMD::checkSelection %W RmsdSel.TEntry
        return 1
        }] -row 0 -column 2 -sticky ew -padx 2
    
    $frame.header.fcolapse.selection.entry insert end "Type Selection"

    QWIKMD::balloon $frame.header.fcolapse.selection.entry [QWIKMD::rmsdGeneralSelectionBL] 

    grid [ttk::frame $frame.header.fcolapse.align ] -row 2 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header.fcolapse.align 0 -weight 0
    grid columnconfigure $frame.header.fcolapse.align 1 -weight 0
    grid columnconfigure $frame.header.fcolapse.align 2 -weight 0
    grid columnconfigure $frame.header.fcolapse.align 3 -weight 2
    
    grid [ttk::checkbutton $frame.header.fcolapse.align.cAlign -text "Align Structure" -variable QWIKMD::advGui(analyze,basic,alicheck)] -row 0 -column 0 -sticky nsw -padx 2
    set QWIKMD::advGui(analyze,basic,alicheck) 0
    

    QWIKMD::balloon $frame.header.fcolapse.align.cAlign [QWIKMD::rmsdAlignBL]

    grid [ttk::combobox $frame.header.fcolapse.align.combo -values $values -width 12 -state readonly] -row 0 -column 1 -sticky nsw -padx 2
    $frame.header.fcolapse.align.combo set "Backbone"
    set QWIKMD::advGui(analyze,basic,alicombo) "backbone"
    
    bind $frame.header.fcolapse.align.combo <<ComboboxSelected>> {
        set text [%W get]
        switch  $text {
            Backbone {
                set QWIKMD::advGui(analyze,basic,alicombo) "backbone"
            }
            "Alpha Carbon" {
                set QWIKMD::advGui(analyze,basic,alicombo) "alpha carbon"
            }
            "No Hydrogen" {
                set QWIKMD::advGui(analyze,basic,alicombo) "noh"
            }
            "All" {
                set QWIKMD::advGui(analyze,basic,alicombo) "all"
            }
            
        }
        %W selection clear
    }

    QWIKMD::balloon $frame.header.fcolapse.align.combo [QWIKMD::rmsdAlignSelection]

    grid [ttk::label $frame.header.fcolapse.align.lbor -text "or"] -row 0 -column 2 -sticky ns -padx 5
    ttk::style configure RmsdAli.TEntry -foreground $QWIKMD::tempEntry
    grid [ttk::entry $frame.header.fcolapse.align.entry -style RmsdAli.TEntry -textvariable QWIKMD::advGui(analyze,basic,alientry) -validate focus -validatecommand {
        QWIKMD::checkSelection %W RmsdAli.TEntry
        return 1
        }] -row 0 -column 3 -sticky ew -padx 2
    $frame.header.fcolapse.align.entry insert end "Type Selection"

    QWIKMD::balloon $frame.header.fcolapse.align.entry [QWIKMD::rmsdGeneralAlignSelectionBL]

    set QWIKMD::rmsdsel "all"
    grid forget $frame.header.fcolapse
}

############################################################
## Temperature values during the live simulation are retrieved 
## from the communication NAMD-VMD. Pressure and Volume are listed
## in the molinfo command, but NAMD never sent these values previously 
############################################################

proc QWIKMD::ThermoFrame {frame} {

    proc checkCondGui {} {
        if {[winfo exists $QWIKMD::CondGui] == 1} {
            if {[winfo ismapped $QWIKMD::CondGui] == 1} {
                $QWIKMD::topGui.nbinput.f2.fp.condit.selection.plot invoke
            }
        }
    }

    grid [ttk::frame $frame.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header 0 -weight 1
    grid [ttk::label $frame.header.lbtitle -text "$QWIKMD::rightPoint Thermodynamics"] -row 0 -column 0 -sticky nw -pady 2 -padx 2

    QWIKMD::createInfoButton $frame.header 0 0
    
    bind $frame.header.lbtitle <Button-1> {
        QWIKMD::hideFrame %W [lindex [grid info %W] 1] "Thermodynamics"
    }
    bind $frame.header.info <Button-1> {
        set val [QWIKMD::condPlotInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow condPlotInfo [lindex $val 0] [lindex $val 2]
    }

    grid [ttk::frame $frame.header.fcolapse ] -row 1 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header.fcolapse 0 -weight 1

    grid [ttk::button $frame.header.fcolapse.plot -text "Calculate" -padding "2 2 2 2" -width 15 -command {
        set ylab "Temperature (K)"
        set xlab "Time (ns)"
        if {$QWIKMD::run == "QM/MM"} {
            set xlab "Time (ps)"
        }    
        set plot 0
        if {$QWIKMD::tempcalc == 1 && $QWIKMD::tempGui == ""}  {
            set plot 1
            set title "AVG Temperature vs Time"

            set info [QWIKMD::addplot tempcalc "Temperature" $title $xlab $ylab]
            set QWIKMD::tempGui [lindex $info 0]

            set clear [lindex $info 1]
            set close [lindex $info 2]
            
            $clear entryconfigure 0 -command {
                $QWIKMD::tempGui clear
                set QWIKMD::tempval [list]
                set QWIKMD::temppos [list]
                $QWIKMD::tempGui add 0 0
                $QWIKMD::tempGui replot
            }

            $close entryconfigure 0 -command {
                $QWIKMD::tempGui quit
                destroy $QWIKMD::advGui(analyze,basic,ntb).tempcalc
                set QWIKMD::tempGui ""
            }
        } elseif {$QWIKMD::tempcalc == 0 && $QWIKMD::tempGui != ""} {
            destroy $QWIKMD::advGui(analyze,basic,ntb).tempcalc
            set QWIKMD::tempGui ""
        }

        if {$QWIKMD::pressurecalc == 1 && $QWIKMD::pressGui == ""}  {
            set plot 1
            set title "AVG Pressure vs Time"
            set ylab "Pressure (bar)"
            set info [QWIKMD::addplot pressurecalc "Pressure" $title $xlab $ylab]
            set QWIKMD::pressGui [lindex $info 0]

            set clear [lindex $info 1]
            set close [lindex $info 2]
            
            $clear entryconfigure 0 -command {
                $QWIKMD::pressGui clear
                set QWIKMD::pressval [list]
                set QWIKMD::pressvalavg [list]
                set QWIKMD::presspos [list]
                $QWIKMD::pressGui add 0 0
                $QWIKMD::pressGui replot
            }

            $close entryconfigure 0 -command {
                $QWIKMD::pressGui quit
                destroy $QWIKMD::advGui(analyze,basic,ntb).pressurecalc
                set QWIKMD::pressGui ""
            }
        } elseif {$QWIKMD::pressurecalc == 0 && $QWIKMD::pressGui != ""} {
            destroy $QWIKMD::advGui(analyze,basic,ntb).pressurecalc
            set QWIKMD::pressGui "" 
        }

        if {$QWIKMD::volumecalc == 1 && $QWIKMD::volGui == ""}  {
            set plot 1
            set title "AVG Volume vs Time"
            set ylab "Volume (A\u00b3)"
            set info [QWIKMD::addplot volumecalc "Volume" $title $xlab $ylab]
            set QWIKMD::volGui [lindex $info 0]

            set clear [lindex $info 1]
            set close [lindex $info 2]
            
            $clear entryconfigure 0 -command {
                $QWIKMD::volGui clear
                set QWIKMD::volval [list]
                set QWIKMD::volvalavg [list]
                set QWIKMD::volpos [list]
                $QWIKMD::volGui add 0 0
                $QWIKMD::volGui replot
            }

            $close entryconfigure 0 -command {
                $QWIKMD::volGui quit
                destroy $QWIKMD::advGui(analyze,basic,ntb).volumecalc
                set QWIKMD::volGui ""
                #set QWIKMD::rmsdplotview 0
            }
        } elseif {$QWIKMD::volumecalc == 0 && $QWIKMD::volGui != ""} {
            destroy $QWIKMD::advGui(analyze,basic,ntb).volumecalc
            set QWIKMD::volGui ""
        }

        if {$plot == 0} {
            if {$QWIKMD::tempGui != ""} {set plot 1}
            if {$QWIKMD::pressGui != ""} {set plot 1}
            if {$QWIKMD::volGui != ""} {set plot 1}
        }    
        if {$QWIKMD::load == 1 && $plot == 1} {
            set const 2e-6  
            set time ""
            set index 0
            set limit [expr $QWIKMD::calcfreq *10]
            set limitaux $limit     
            set tempvalaux [list]
            set pressvalaux [list]
            set volvalaux [list]
            set tempaux 0
            set pressaux 0
            set volaux 0
            set QWIKMD::condprevx 0
            set QWIKMD::condprevindex 0
            set loadcondprevindex 0
            set energyfreqaux 1
            set energyfreq 1
            set print 0
            set tstepaux 0
            set window 10
            set prevxtime 0
            if {$QWIKMD::tempGui != "" && [llength $QWIKMD::temppos] == 0} {set tempaux 1}
            if {$QWIKMD::pressGui != "" && [llength $QWIKMD::presspos] == 0} {set pressaux 1}
            if {$QWIKMD::volGui != "" && [llength $QWIKMD::volpos] == 0} {set volaux 1}

            if {$tempaux ==1 || $pressaux ==1 || $volaux == 1} {
                set index 0
                set print 1
                for {set i 0} {$i < [llength $QWIKMD::confFile]} {incr i} {
                    set file "[lindex $QWIKMD::confFile $i].log"
                    if {[file exists $file] !=1} {
                        break
                    }
                    
                    set logfile [open $file r]
                    ## prevtmstp records the previous timestep number to avoid double count 
                    ## when NAMD prints the same timestep twice (possible bug)
                    set prevtmstp ""
                    set reset 0
                    while {[eof $logfile] != 1 } {
                        set line [gets $logfile]

                        if {[lindex $line 0] == "Info:" && [lindex $line 1] == "TIMESTEP"} {
                            set aux [lindex $line 2]
                            set const [expr $aux * 1e-6]
                            if {$QWIKMD::run == "QM/MM"} {
                                set const [expr $const * 1e3]
                                set limit 10
                                set limitaux 10
                            } 
                            set tstepaux 0
                        }
                        
                        if {[lindex $line 0] == "Info:" && [join [lrange $line 1 3]] == "ENERGY OUTPUT STEPS" } {
                            set energyfreq [lindex $line 4]
                            set energyfreqaux $energyfreq
                            set tabid [lindex [lindex $QWIKMD::selnotbooks 0] 1]
                            if {$QWIKMD::basicGui(live,$tabid) == 0 && $QWIKMD::run != "QM/MM"} {
                                set limit [expr $energyfreq * $window] 
                                set limitaux $limit     
                            }
                        }

                        if {[lindex $line 0] == "TCL:" && [lindex $line 1] == "Minimizing" } {
                            set energyfreq 1
                            set limit $window
                        }
                        if {[lindex $line 0] == "TCL:" && [lindex $line 1] == "Running" && $reset == 0 } {
                            set energyfreq $energyfreqaux
                            set limit $limitaux     
                            set tstepaux 0
                            set reset 1
                        }

                        if {[lindex $line 0] == "ENERGY:" && [lindex $line 1] != $prevtmstp} {
                            if {$tempaux == 1} {
                                lappend  tempvalaux [lindex $line 15]
                            }

                            if {$pressaux == 1} {
                                lappend  pressvalaux [lindex $line 19]
                            }

                            if {$volaux == 1} {
                                lappend  volvalaux [lindex $line 18]
                            }
                            incr index $energyfreq
                            incr tstepaux $energyfreq
                            set prevtmstp [lindex $line 1]
                        } 
                        if {[expr $tstepaux % $limit] == 0 && $index != $loadcondprevindex} {
                            set xtime [QWIKMD::format4Dec  [expr $const * $index]]
                            if {$tempaux ==1 && [llength $tempvalaux] > 0} {
                                
                                set min 0
                                set minaux [expr int([expr [llength $tempvalaux] - [expr 1.5 * $window] -1])]  
                                if {$minaux > 0} {
                                    set min $minaux
                                }
                                
                                set max [expr [llength $tempvalaux] -1]
                                lappend QWIKMD::tempval [QWIKMD::mean [lrange $tempvalaux $min $max]]
                                lappend QWIKMD::temppos $xtime
                            }
                            
                            if {$pressaux ==1 && [llength $pressvalaux] > 0} {
                                set min 0
                                set minaux [expr int([expr [llength $pressvalaux] - [expr 1.5 * $window] -1])]
                                if {$minaux > 0} {
                                    set min $minaux  
                                }
                                
                                set max [expr [llength $pressvalaux] -1]
                            
                                lappend QWIKMD::pressvalavg [QWIKMD::mean [lrange $pressvalaux $min $max]]
                                lappend QWIKMD::presspos $xtime
                            }
                            if {$volaux == 1 && [llength $volvalaux] > 0} {

                                set min 0
                                set minaux [expr int([expr [llength $volvalaux] - [expr 1.5 * $window] -1])]
                                if {$minaux > 0} {
                                    set min $minaux  
                                }
                                
                                set max [expr [llength $volvalaux] -1]
                            
                                lappend QWIKMD::volvalavg [QWIKMD::mean [lrange $volvalaux $min $max]]
                                lappend QWIKMD::volpos $xtime
                            }
                            
                            set loadcondprevindex $index
                        }
                        
                    }
                    if {[lindex $QWIKMD::temppos end] != "" && $tempaux ==1} {
                        set QWIKMD::condprevx [lindex $QWIKMD::temppos end]
                    } elseif {[lindex $QWIKMD::presspos end] != "" && $pressaux ==1} {
                        set QWIKMD::condprevx [lindex $QWIKMD::presspos end]

                    } elseif {[lindex $QWIKMD::volpos end] != "" && $volaux ==1} {
                        set QWIKMD::condprevx [lindex $QWIKMD::volpos end]
                    }
                    if {$print == 1} {
                        set time [expr $xtime - $prevxtime]
                        puts $QWIKMD::textLogfile [QWIKMD::printThermo [lindex $QWIKMD::confFile $i].log $time $limit [expr 1.5 * $window] $energyfreq $const $tempaux $pressaux $volaux]
                        set prevxtime $xtime
                        flush $QWIKMD::textLogfile
                    }
                    if {$reset == 0} {
                        set tempvalaux [list]
                        set pressvalaux [list]
                        set volvalaux [list]
                    }
                    close $logfile  
                 }
            }
            if {$QWIKMD::tempGui != "" && [llength $QWIKMD::temppos] > 1} {
                $QWIKMD::tempGui clear
                $QWIKMD::tempGui add $QWIKMD::temppos $QWIKMD::tempval
                $QWIKMD::tempGui replot
            }
            if {$QWIKMD::pressGui != "" && [llength $QWIKMD::presspos] > 1 != ""} {
                $QWIKMD::pressGui clear
                $QWIKMD::pressGui add $QWIKMD::presspos $QWIKMD::pressvalavg
                $QWIKMD::pressGui replot
            }
            if {$QWIKMD::volGui != "" && [llength $QWIKMD::volpos] > 1 != ""} {
                $QWIKMD::volGui clear
                $QWIKMD::volGui add $QWIKMD::volpos $QWIKMD::volvalavg
                $QWIKMD::volGui replot
            }
            

        } elseif {$QWIKMD::load == 0} {
            QWIKMD::CondCalc
        }

    } ] -row 0 -column 0 -sticky ens -pady 2 -padx 1

    
    QWIKMD::balloon $frame.header.fcolapse.plot [QWIKMD::condCalcBL]

    grid [ttk::frame $frame.header.fcolapse.selection ] -row 1 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header.fcolapse.selection 0 -weight 1
    grid columnconfigure $frame.header.fcolapse.selection 1 -weight 1
    grid columnconfigure $frame.header.fcolapse.selection 2 -weight 1

    grid [ttk::checkbutton $frame.header.fcolapse.selection.temp -text "Temperature" -variable QWIKMD::tempcalc -command [namespace current]::checkCondGui] -row 0 -column 0 -sticky w -pady 2 -padx 4
    grid [ttk::checkbutton $frame.header.fcolapse.selection.press -text "Pressure" -variable QWIKMD::pressurecalc -command [namespace current]::checkCondGui] -row 0 -column 1 -sticky w -pady 2 -padx 4 
    grid [ttk::checkbutton $frame.header.fcolapse.selection.volume -text "Volume" -variable QWIKMD::volumecalc -command [namespace current]::checkCondGui] -row 0 -column 2 -sticky w -pady 2 -padx 4

    set QWIKMD::advGui(analyze,advance,pressbtt) $frame.header.fcolapse.selection.press
    set QWIKMD::advGui(analyze,advance,volbtt) $frame.header.fcolapse.selection.volume
    QWIKMD::balloon $frame.header.fcolapse.selection.temp [QWIKMD::condTemp]
    QWIKMD::balloon $frame.header.fcolapse.selection.press [QWIKMD::condPress]
    QWIKMD::balloon $frame.header.fcolapse.selection.volume [QWIKMD::condVolume]
    grid forget $frame.header.fcolapse
    
}

proc QWIKMD::EnerFrame {frame} {

    # proc checkEnergyGui {} {
    #   if {[winfo exists $QWIKMD::EnergyGui] == 1} {
    #       if {[winfo ismapped $QWIKMD::EnergyGui] == 1} {
    #           #$QWIKMD::topGui.nbinput.f2.fp.energies.selection.plot invoke
    #       }
    #   }
    # }
    grid [ttk::frame $frame.general ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.general 0 -weight 1

    set frame "$frame.general"
    grid [ttk::frame $frame.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header 0 -weight 1
    
    grid [ttk::label $frame.header.lbtitle -text "$QWIKMD::rightPoint Energies"] -row 0 -column 0 -sticky nw -pady 2 -padx 2
    
    bind $frame.header.lbtitle <Button-1> {
        QWIKMD::hideFrame %W [lindex [grid info %W] 1] "Energies"
    }

    QWIKMD::createInfoButton $frame.header 0 0

    bind $frame.header.info <Button-1> {
        set val [QWIKMD::energiesPlotInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow energiesPlotInfo [lindex $val 0] [lindex $val 2]
    }

    grid [ttk::frame $frame.header.fcolapse ] -row 1 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header.fcolapse 0 -weight 1
    grid [ttk::button $frame.header.fcolapse.plot -text "Calculate" -padding "2 2 2 2" -width 15 -command {
        set xlab "Time (ns)"
        if {$QWIKMD::run == "QM/MM"} {
            set xlab "Time (ps)"
        }
        set ylab "AVG Energy\n(kcal/mol)"
        set plot 0
        if {$QWIKMD::enertotal == 1 && $QWIKMD::energyTotGui == ""}  {
            set plot 1
            set title "AVG Total Energy vs Time"

            set info [QWIKMD::addplot enertotal "Total Energy" $title $xlab $ylab]
            set QWIKMD::energyTotGui [lindex $info 0]

            set clear [lindex $info 1]
            set close [lindex $info 2]
            
            $clear entryconfigure 0 -command {
                $QWIKMD::energyTotGui clear
                set QWIKMD::enetotval [list]
                set QWIKMD::enetotpos [list]
                $QWIKMD::energyTotGui add 0 0
                $QWIKMD::energyTotGui replot
            }
            $close entryconfigure 0 -command {
                $QWIKMD::energyTotGui quit
                destroy $QWIKMD::advGui(analyze,basic,ntb).enertotal
                set QWIKMD::energyTotGui ""
            }
        } elseif {$QWIKMD::enertotal == 0 && $QWIKMD::energyTotGui != ""} {
            destroy $QWIKMD::advGui(analyze,basic,ntb).enertotal
            set QWIKMD::energyTotGui ""
        }

        if {$QWIKMD::enerkinetic == 1 && $QWIKMD::energyKineGui == ""} {

            set plot 1
            set title "AVG Kinetic Energy vs Time"

            set info [QWIKMD::addplot enerkinetic "Kinetic Energy" $title $xlab $ylab]
            set QWIKMD::energyKineGui  [lindex $info 0]

            set clear [lindex $info 1]
            set close [lindex $info 2]
            
            $clear entryconfigure 0 -command {
                $QWIKMD::energyKineGui clear
                set QWIKMD::enekinval [list]
                set QWIKMD::enekinpos [list]
                $QWIKMD::energyKineGui add 0 0
                $QWIKMD::energyKineGui replot
            }

            $close entryconfigure 0 -command {
                $QWIKMD::energyKineGui quit
                destroy $QWIKMD::advGui(analyze,basic,ntb).enerkinetic
                set QWIKMD::energyKineGui ""
                
            }
        } elseif {$QWIKMD::enerkinetic == 0 && $QWIKMD::energyKineGui != ""} {
            destroy $QWIKMD::advGui(analyze,basic,ntb).enerkinetic
            set QWIKMD::energyKineGui ""
        }

        if {$QWIKMD::enerelect == 1 && $QWIKMD::energyElectGui == ""} {

            set plot 1
            set title "AVG Electrostatic Energy vs Time"

            set info [QWIKMD::addplot enerelect "Electrostatic Energy" $title $xlab $ylab]
            set QWIKMD::energyElectGui  [lindex $info 0]

            set clear [lindex $info 1]
            set close [lindex $info 2]
            
            $clear entryconfigure 0 -command {
                $QWIKMD::energyElectGui clear
                set QWIKMD::eneelectval [list]
                set QWIKMD::eneelectpos [list]
                $QWIKMD::energyElectGui add 0 0
                $QWIKMD::energyElectGui replot
            }

            $close entryconfigure 0 -command {
                $QWIKMD::energyElectGui quit
                destroy $QWIKMD::advGui(analyze,basic,ntb).enerelect
                set QWIKMD::energyElectGui ""
                
            }
        } elseif {$QWIKMD::enerelect == 0 && $QWIKMD::energyElectGui != ""} {
            destroy $QWIKMD::advGui(analyze,basic,ntb).enerelect
            set QWIKMD::energyElectGui ""
        }
    
        if {$QWIKMD::enerpoten == 1 && $QWIKMD::energyPotGui == ""} {

            set plot 1
            set title "AVG Potential Energy vs Time"

            set info [QWIKMD::addplot enerpoten "Potential Energy" $title $xlab $ylab]
            set QWIKMD::energyPotGui  [lindex $info 0]

            set clear [lindex $info 1]
            set close [lindex $info 2]
            
            $clear entryconfigure 0 -command {
                $QWIKMD::energyPotGui clear
                set QWIKMD::enekinval [list]
                set QWIKMD::enekinpos [list]
                $QWIKMD::energyPotGui add 0 0
                $QWIKMD::energyPotGui replot
            }

            $close entryconfigure 0 -command {
                $QWIKMD::energyPotGui quit
                destroy $QWIKMD::advGui(analyze,basic,ntb).enerpoten
                set QWIKMD::energyPotGui ""
            }
        } elseif {$QWIKMD::enerpoten == 0 && $QWIKMD::energyPotGui != ""} {
            destroy $QWIKMD::advGui(analyze,basic,ntb).enerpoten
            set QWIKMD::energyPotGui ""
        }
        

        if {$QWIKMD::enerbond == 1 && $QWIKMD::energyBondGui == ""} {
            set plot 1
            set title "AVG Bond Energy vs Time"

            set info [QWIKMD::addplot enerbond "Bond Energy" $title $xlab $ylab]
            set QWIKMD::energyBondGui  [lindex $info 0]

            set clear [lindex $info 1]
            set close [lindex $info 2]
            
            $clear entryconfigure 0 -command {
                $QWIKMD::energyBondGui clear
                set QWIKMD::enebondval [list]
                set QWIKMD::enebondpos [list]
                $QWIKMD::energyBondGui add 0 0
                $QWIKMD::energyBondGui replot
            }

            $close entryconfigure 0 -command {
                $QWIKMD::energyBondGui quit
                destroy $QWIKMD::advGui(analyze,basic,ntb).enerbond
                set QWIKMD::energyBondGui ""
            }
        } elseif {$QWIKMD::enerbond == 0 && $QWIKMD::energyBondGui != ""} {
            destroy $QWIKMD::advGui(analyze,basic,ntb).enerbond
            set QWIKMD::energyBondGui ""
        }

        if {$QWIKMD::enerangle == 1 && $QWIKMD::energyAngleGui == ""} {
            set plot 1
            set title "AVG Angle Energy vs Time"
            set info [QWIKMD::addplot enerangle "Angle Energy" $title $xlab $ylab]
            set QWIKMD::energyAngleGui  [lindex $info 0]

            set clear [lindex $info 1]
            set close [lindex $info 2]
            
            $clear entryconfigure 0 -command {
                $QWIKMD::energyAngleGui clear
                set QWIKMD::eneangleval [list]
                set QWIKMD::eneanglepos [list]
                $QWIKMD::energyAngleGui add 0 0
                $QWIKMD::energyAngleGui replot
            }

            $close entryconfigure 0 -command {
                $QWIKMD::energyAngleGui quit
                destroy $QWIKMD::advGui(analyze,basic,ntb).enerangle
                set QWIKMD::energyAngleGui ""
            }
        } elseif {$QWIKMD::enerangle == 0 && $QWIKMD::energyAngleGui != ""} {
            destroy $QWIKMD::advGui(analyze,basic,ntb).enerangle
            set QWIKMD::energyAngleGui ""
        }

        if {$QWIKMD::enerdihedral == 1 && $QWIKMD::energyDehidralGui == ""} {
            set plot 1
            set title "AVG Dihedral Energy vs Time"
            set info [QWIKMD::addplot enerdihedral "Dihedral Energy" $title $xlab $ylab]
            set QWIKMD::energyDehidralGui  [lindex $info 0]

            set clear [lindex $info 1]
            set close [lindex $info 2]
            
            $clear entryconfigure 0 -command {
                $QWIKMD::energyDehidralGui clear
                set QWIKMD::enedihedralval [list]
                set QWIKMD::enedihedralpos [list]
                $QWIKMD::energyDehidralGui add 0 0
                $QWIKMD::energyDehidralGui replot
            }

            $close entryconfigure 0 -command {
                $QWIKMD::energyDehidralGui quit
                destroy $QWIKMD::advGui(analyze,basic,ntb).enerdihedral
                set QWIKMD::energyDehidralGui ""
            }
        } elseif {$QWIKMD::enerdihedral == 0 && $QWIKMD::energyDehidralGui != ""} {
            destroy $QWIKMD::advGui(analyze,basic,ntb).enerdihedral
            set QWIKMD::energyDehidralGui ""
        }

        if {$QWIKMD::enervdw == 1 && $QWIKMD::energyVdwGui == ""} {
            set plot 1
            set title "AVG VDW Energy vs Time"
            set info [QWIKMD::addplot enervdw "VDW Energy" $title $xlab $ylab]
            set QWIKMD::energyVdwGui  [lindex $info 0]

            set clear [lindex $info 1]
            set close [lindex $info 2]
            
            $clear entryconfigure 0 -command {
                $QWIKMD::energyVdwGui clear
                set QWIKMD::enevdwval [list]
                set QWIKMD::enevdwpos [list]
                $QWIKMD::energyVdwGui add 0 0
                $QWIKMD::energyVdwGui replot
            }

            $close entryconfigure 0 -command {
                $QWIKMD::energyVdwGui quit
                destroy $QWIKMD::advGui(analyze,basic,ntb).enervdw
                set QWIKMD::energyVdwGui ""
            }
        } elseif {$QWIKMD::enervdw == 0 && $QWIKMD::energyVdwGui != ""} {
            destroy $QWIKMD::advGui(analyze,basic,ntb).enervdw
            set QWIKMD::energyVdwGui ""
        }
        if {$plot == 0} {
            if {$QWIKMD::energyTotGui != ""} {set plot 1}
            if {$QWIKMD::energyPotGui != ""} {set plot 1}
            if {$QWIKMD::energyKineGui != ""} {set plot 1}
            if {$QWIKMD::energyElectGui != ""} {set plot 1}
            if {$QWIKMD::energyBondGui != ""} {set plot 1}
            if {$QWIKMD::energyAngleGui != ""} {set plot 1}
            if {$QWIKMD::energyDehidralGui != "" } {set plot 1}
            if {$QWIKMD::energyVdwGui != ""} {set plot 1}
        }
        if {$QWIKMD::load == 1 && $plot == 1} {
            
            set time ""
            set index 0
            
            
            set enetotvalaux [list]
            set enekinvalaux [list]
            set eneelectvalaux [list]
            set enepotvalaux [list]

            set enebondvalaux [list]
            set eneanglevalaux [list]
            set enedihedralvalaux [list]
            set enevdwvalaux [list]
            set tot 0
            set kin 0
            set elect 0
            set pot 0
            set bond 0
            set angle 0
            set dihedral 0
            set vdw 0
            set QWIKMD::eneprevx 0
            
            if {$QWIKMD::energyTotGui != "" && [llength $QWIKMD::enetotpos] == 0} {set tot 1}
            if {$QWIKMD::energyPotGui != "" && [llength $QWIKMD::enepotpos] == 0} {set pot 1}
            if {$QWIKMD::energyElectGui != "" && [llength $QWIKMD::eneelectpos] == 0} {set elect 1}
            if {$QWIKMD::energyKineGui != "" && [llength $QWIKMD::enekinpos] == 0} {set kin 1}
            if {$QWIKMD::energyBondGui != "" && [llength $QWIKMD::enebondpos] == 0} {set bond 1}
            if {$QWIKMD::energyAngleGui != "" && [llength $QWIKMD::eneanglepos] == 0} {set angle 1}
            if {$QWIKMD::energyDehidralGui != "" && [llength $QWIKMD::enedihedralpos] == 0} {set dihedral 1}
            if {$QWIKMD::energyVdwGui != "" && [llength $QWIKMD::enevdwpos] == 0} {set vdw 1}
            set print 0
            set xtime 0
            set limit [expr $QWIKMD::calcfreq * 10]
            set limitaux $limit 
            set print 1
            set energyfreq 1
            set const 2e-6  
            set tstep 0
            set tstepaux 0
            set eneprevindex 0
            set energyfreqaux 1
            set window 10
            set prevxtime 0
            if {$tot ==1 || $pot ==1 || $kin == 1 || $elect == 1 || $bond ==1 || $angle == 1|| $dihedral ==1 || $vdw == 1 } {
                
                for {set i 0} {$i < [llength $QWIKMD::confFile]} {incr i} {
                    set file "[lindex $QWIKMD::confFile $i].log"
                    if {[file exists $file] != 1} {
                        break
                    }
                    
                    set logfile [open $file r]
                    set prevtmstp ""
                    set reset 0
                    while {[eof $logfile] != 1 } {
                        set line [gets $logfile]

                        if {[lindex $line 0] == "Info:" && [lindex $line 1] == "TIMESTEP"} {
                            set aux [lindex $line 2]
                            set const [expr $aux * 1e-6]
                            if {$QWIKMD::run == "QM/MM"} {
                                set const [expr $const * 1e3]
                                set limit 10
                                set limitaux 10
                            }
                            set tstepaux 0
                        }
                        
                        if {[lindex $line 0] == "Info:" && [join [lrange $line 1 3]] == "ENERGY OUTPUT STEPS" } {
                            set energyfreq [lindex $line 4]
                            set energyfreqaux $energyfreq
                            set tabid [lindex [lindex $QWIKMD::selnotbooks 0] 1]
                            if {$QWIKMD::basicGui(live,$tabid) == 0 && $QWIKMD::run != "QM/MM"} {
                                set limit [expr $energyfreq * $window] 
                                set limitaux $limit 
                            }
                        }

                        if {[lindex $line 0] == "TCL:" && [lindex $line 1] == "Minimizing" } {
                            set energyfreq 1
                            set limit $window
                        }
                        if {[lindex $line 0] == "TCL:" && [lindex $line 1] == "Running" && $reset == 0 } {
                            set energyfreq $energyfreqaux
                            set limit $limitaux     
                            set tstepaux 0
                            set reset 1
                        }

                        if {[lindex $line 0] == "ENERGY:" && [lindex $line 1] != $prevtmstp} {


                            if {$bond == 1} {
                                lappend  enebondvalaux [lindex $line 2]
                            }

                            if {$angle == 1} {
                                lappend  eneanglevalaux [lindex $line 3]
                            }

                            if {$dihedral == 1} {
                                lappend  enedihedralvalaux [lindex $line 4]
                            }

                            if {$vdw == 1} {
                                lappend  enevdwvalaux [lindex $line 7]
                            }

                            if {$tot == 1} {
                                lappend  enetotvalaux [lindex $line 11]
                            }
                            if {$elect == 1} {
                                lappend  eneelectvalaux [lindex $line 6]
                            }

                            if {$kin == 1} {
                                lappend  enekinvalaux [lindex $line 10]
                            }

                            if {$pot == 1} {
                                lappend  enepotvalaux [lindex $line 13]
                            }

                            incr tstep $energyfreq
                            incr tstepaux $energyfreq
                            set prevtmstp [lindex $line 1] 
                        }
                        if {[expr $tstepaux % $limit] == 0 && $tstep != $eneprevindex} {
                            set xtime [QWIKMD::format4Dec [expr $const * $tstep ]]
                            if {$bond ==1 && [llength $enebondvalaux] > 0} {
                                
                                set min 0
                                set minaux [expr int([expr [llength $enebondvalaux] - [expr 1.5 * $window] -1])]  
                                if {$minaux > 0} {
                                    set min $minaux  
                                }
                                
                                set max [expr [llength $enebondvalaux] -1]
                            
                                lappend QWIKMD::enebondval [QWIKMD::mean [lrange $enebondvalaux $min $max]]
                                lappend QWIKMD::enebondpos $xtime
                            }

                            if {$angle ==1 && [llength $eneanglevalaux] > 0} {
                                
                                set min 0
                                set minaux [expr int([expr [llength $eneanglevalaux] - [expr 1.5 * $window] -1])] 
                                if {$minaux > 0} {
                                    set min $minaux  
                                }
                                
                                set max [expr [llength $eneanglevalaux] -1]
                            
                                lappend QWIKMD::eneangleval [QWIKMD::mean [lrange $eneanglevalaux $min $max]]
                                lappend QWIKMD::eneanglepos $xtime
                            }

                            if {$dihedral ==1 && [llength $enedihedralvalaux] > 0} {
                                
                                set min 0
                                set minaux [expr int([expr [llength $enedihedralvalaux] - [expr 1.5 * $window] -1])] 
                                if {$minaux > 0} {
                                    set min  $minaux
                                }
                                
                                set max [expr [llength $enedihedralvalaux] -1]
                            
                                lappend QWIKMD::enedihedralval [QWIKMD::mean [lrange $enedihedralvalaux $min $max]]
                                lappend QWIKMD::enedihedralpos $xtime
                            }

                            if {$vdw ==1 && [llength $enevdwvalaux] > 0} {
                                
                                set min 0
                                set minaux [expr int([expr [llength $enevdwvalaux] - [expr 1.5 * $window] -1])]  
                                if {$minaux > 0} {
                                    set min $minaux 
                                }
                                
                                set max [expr [llength $enevdwvalaux] -1]
                            
                                lappend QWIKMD::enevdwval [QWIKMD::mean [lrange $enevdwvalaux $min $max]]
                                lappend QWIKMD::enevdwpos $xtime
                            }

                            if {$tot ==1 && [llength $enetotvalaux] > 0} {
                                
                                set min 0
                                set minaux [expr int([expr [llength $enetotvalaux] - [expr 1.5 * $window] -1])]  
                                if {$minaux > 0} {
                                    set min $minaux
                                }
                                
                                set max [expr [llength $enetotvalaux] -1]
                            
                                lappend QWIKMD::enetotval [QWIKMD::mean [lrange $enetotvalaux $min $max]]
                                lappend QWIKMD::enetotpos $xtime
                            }
                            
                            if {$kin ==1 && [llength $enekinvalaux] > 0} {
                                set min 0
                                set minaux [expr int([expr [llength $enekinvalaux] - [expr 1.5 * $window] -1])]
                                if {$minaux > 0} {
                                    set min $minaux   
                                }
                                
                                set max [expr [llength $enekinvalaux] -1]
                            
                                lappend QWIKMD::enekinval [QWIKMD::mean [lrange $enekinvalaux $min $max]]
                                lappend QWIKMD::enekinpos $xtime
                            }

                            if {$elect == 1 && [llength $eneelectvalaux] > 0} {
                                set min 0
                                set minaux [expr int([expr [llength $eneelectvalaux] - [expr 1.5 * $window] -1])]
                                if {$minaux > 0} {
                                    set min $minaux   
                                }
                                
                                set max [expr [llength $eneelectvalaux] -1]
                            
                                lappend QWIKMD::eneelectval [QWIKMD::mean [lrange $eneelectvalaux $min $max]]
                                lappend QWIKMD::eneelectpos $xtime
                            }

                            if {$pot == 1 && [llength $enepotvalaux] > 0} {

                                set min 0
                                set minaux [expr int([expr [llength $enepotvalaux] - [expr 1.5 * $window] -1])]
                                if {$minaux > 0} {
                                    set min $minaux   
                                }
                                
                                set max [expr [llength $enepotvalaux] -1]
                            
                                lappend QWIKMD::enepotval [QWIKMD::mean [lrange $enepotvalaux $min $max]]
                                lappend QWIKMD::enepotpos $xtime
                            }
                            
                            set eneprevindex $tstep
                        }
                        
                    }
                    
                    if {[lindex $QWIKMD::enetotpos end] != "" && $tot ==1} {
                        set QWIKMD::eneprevx [lindex $QWIKMD::enetotpos end]
                    } elseif {[lindex $QWIKMD::enekinpos end] != "" && $kin ==1} {
                        set QWIKMD::eneprevx [lindex $QWIKMD::enekinpos end]

                    } elseif {[lindex $QWIKMD::eneelectpos end] != "" && $elect ==1} {
                        set QWIKMD::eneprevx [lindex $QWIKMD::eneelectpos end]
                    } elseif {[lindex $QWIKMD::enepotpos end] != "" && $pot ==1} {
                        set QWIKMD::eneprevx [lindex $QWIKMD::enepotpos end]
                    } elseif {[lindex $QWIKMD::enebondpos end] != "" && $bond ==1} {
                        set QWIKMD::eneprevx [lindex $QWIKMD::enebondpos end]
                    } elseif {[lindex $QWIKMD::eneanglepos end] != "" && $angle ==1} {
                        set QWIKMD::eneprevx [lindex $QWIKMD::eneanglepos end]
                    } elseif {[lindex $QWIKMD::enedihedralpos end] != "" && $dihedral ==1} {
                        set QWIKMD::eneprevx [lindex $QWIKMD::enedihedralpos end]
                    } elseif {[lindex $QWIKMD::enevdwpos end] != "" && $vdw ==1} {
                        set QWIKMD::eneprevx [lindex $QWIKMD::enevdwpos end]
                    }   
                        
                    if {$print == 1} {
                        set time [expr $xtime - $prevxtime]
                        puts $QWIKMD::textLogfile [QWIKMD::printEnergies [lindex $QWIKMD::confFile $i].log $time $limit [expr 1.5 * $window] $energyfreq $const $tot $kin $elect $pot $bond $angle $dihedral $vdw]
                        set prevxtime $xtime
                        flush $QWIKMD::textLogfile
                    }
                    if {$reset == 0} {
                        set enetotvalaux [list]
                        set enekinvalaux [list]
                        set eneelectvalaux [list]
                        set enepotvalaux [list]
                        set enebondvalaux [list]
                        set eneanglevalaux [list]
                        set enedihedralvalaux [list]
                        set enevdwvalaux [list]
                    }
                    close $logfile  
                 }
            }
            
            if {$QWIKMD::energyTotGui != ""} {
                $QWIKMD::energyTotGui clear
                $QWIKMD::energyTotGui add $QWIKMD::enetotpos $QWIKMD::enetotval
                $QWIKMD::energyTotGui replot
            }
            if {$QWIKMD::energyElectGui != ""} {
                $QWIKMD::energyElectGui clear
                $QWIKMD::energyElectGui add $QWIKMD::eneelectpos $QWIKMD::eneelectval
                $QWIKMD::energyElectGui replot
            }
            if {$QWIKMD::energyKineGui != ""} {
                $QWIKMD::energyKineGui clear
                $QWIKMD::energyKineGui add $QWIKMD::enekinpos $QWIKMD::enekinval
                $QWIKMD::energyKineGui replot
            }
            if {$QWIKMD::energyPotGui != ""} {
                $QWIKMD::energyPotGui clear
                $QWIKMD::energyPotGui add $QWIKMD::enepotpos $QWIKMD::enepotval
                $QWIKMD::energyPotGui replot
            }


            if {$QWIKMD::energyBondGui != ""} {
                $QWIKMD::energyBondGui clear
                $QWIKMD::energyBondGui add $QWIKMD::enebondpos $QWIKMD::enebondval
                $QWIKMD::energyBondGui replot
            }
            if {$QWIKMD::energyAngleGui != ""} {
                $QWIKMD::energyAngleGui clear
                $QWIKMD::energyAngleGui add $QWIKMD::eneanglepos $QWIKMD::eneangleval
                $QWIKMD::energyAngleGui replot
            }
            if {$QWIKMD::energyDehidralGui != ""} {
                $QWIKMD::energyDehidralGui clear
                $QWIKMD::energyDehidralGui add $QWIKMD::enedihedralpos $QWIKMD::enedihedralval
                $QWIKMD::energyDehidralGui replot
            }

            if {$QWIKMD::energyVdwGui != ""} {
                $QWIKMD::energyVdwGui clear
                $QWIKMD::energyVdwGui add $QWIKMD::enevdwpos $QWIKMD::enevdwval
                $QWIKMD::energyVdwGui replot
            }
            
            
        } elseif {$QWIKMD::load == 0} {
            QWIKMD::EneCalc
        }

    } ] -row 0 -column 0 -sticky ens -pady 2 -padx 1

    
    QWIKMD::balloon $frame.header.fcolapse.plot [QWIKMD::enerCalcBL]
    

    grid [ttk::frame $frame.header.fcolapse.selection ] -row 1 -column 0 -sticky we -pady 1 -padx 2 
    grid columnconfigure $frame.header.fcolapse.selection 0 -weight 1
    grid columnconfigure $frame.header.fcolapse.selection 1 -weight 1
    grid columnconfigure $frame.header.fcolapse.selection 2 -weight 1

    grid [ttk::checkbutton $frame.header.fcolapse.selection.total -text "Total" -variable QWIKMD::enertotal] -row 0 -column 0 -sticky nsw -pady 2 -padx 2
    grid [ttk::checkbutton $frame.header.fcolapse.selection.kinetic -text "Kinetic" -variable QWIKMD::enerkinetic] -row 0 -column 1 -sticky nsw -pady 2 -padx 2
    grid [ttk::checkbutton $frame.header.fcolapse.selection.electro -text "Electrostatic" -variable QWIKMD::enerelect] -row 0 -column 2 -sticky nsw -pady 2 -padx 2 
    grid [ttk::checkbutton $frame.header.fcolapse.selection.potential -text "Potential" -variable QWIKMD::enerpoten ] -row 0 -column 3 -sticky nsw -pady 2 -padx 2

    QWIKMD::balloon $frame.header.fcolapse.selection.total  [QWIKMD::energyTotal]
    QWIKMD::balloon $frame.header.fcolapse.selection.kinetic  [QWIKMD::energyKinetic]
    QWIKMD::balloon $frame.header.fcolapse.selection.electro  [QWIKMD::energyElectrostatic]
    QWIKMD::balloon $frame.header.fcolapse.selection.potential  [QWIKMD::energyPotential]

    grid [ttk::checkbutton $frame.header.fcolapse.selection.bond -text "Bond" -variable QWIKMD::enerbond ] -row 1 -column 0 -sticky nsw -pady 2 -padx 2
    grid [ttk::checkbutton $frame.header.fcolapse.selection.angle -text "Angle" -variable QWIKMD::enerangle ] -row 1 -column 1 -sticky nsw -pady 2 -padx 2
    grid [ttk::checkbutton $frame.header.fcolapse.selection.dihedral -text "Dihedral" -variable QWIKMD::enerdihedral ] -row 1 -column 2 -sticky nsw -pady 2 -padx 2
    grid [ttk::checkbutton $frame.header.fcolapse.selection.vdw -text "VDW" -variable QWIKMD::enervdw ] -row 1 -column 3 -sticky nsw -pady 2 -padx 2

    QWIKMD::balloon $frame.header.fcolapse.selection.bond  [QWIKMD::energyBond]
    QWIKMD::balloon $frame.header.fcolapse.selection.angle  [QWIKMD::energyAngle]
    QWIKMD::balloon $frame.header.fcolapse.selection.dihedral  [QWIKMD::energyDihedral]
    QWIKMD::balloon $frame.header.fcolapse.selection.vdw  [QWIKMD::energyVDW]

    grid forget $frame.header.fcolapse
}

#########################################
## Build Render options frame to control
## color scheme and materials 
#########################################
proc QWIKMD::RenderFrame {frame} {

    grid [ttk::frame $frame.res ] -row 0 -column 0 -sticky nsw -pady 1 -padx 1 
    grid columnconfigure $frame.res 0 -weight 0

    grid [ttk::label $frame.res.lbres -text "Resolution" -padding "0 0 6 0"] -row 0 -column 0 -sticky nsw -pady 1
    set values {"Window" "1080p" "720p" "480p"}
    grid [ttk::combobox $frame.res.combores -width 8 -justify left -values $values -state readonly -textvariable QWIKMD::basicGui(res)] -row 0 -column 1 -sticky nsw -pady 1
    set QWIKMD::basicGui(res) "Window"
    bind $frame.res.combores <<ComboboxSelected>> {
        set comboVal [%W get]
        set wmSize [display get size]
        if {$comboVal != "Window" || ($wmSize != [list 1920 1080] && $wmSize != [list 1280 720] && $wmSize != [list 640 480])} {
            set QWIKMD::basicGui(wsize) [display get size]
        }
        if {$comboVal == "1080p"} {
            display resize 1920 1080
        } elseif {$comboVal == "720p"} {
            display resize 1280 720
        } elseif {$comboVal == "480p"} {
            display resize 640 480
        } else {
            display resize [lindex $QWIKMD::basicGui(wsize) 0] [lindex $QWIKMD::basicGui(wsize) 1]
        }
        %W selection clear
    }
    set QWIKMD::basicGui(wsize) [display get size]

    QWIKMD::balloon $frame.res.combores [QWIKMD::renderResBL]

    grid [ttk::frame $frame.quality ] -row 0 -column 1 -sticky nsw -pady 1 -padx 1 
    grid columnconfigure $frame.quality 0 -weight 1

    grid [ttk::label $frame.quality.lqual -text "Quality"] -row 0 -column 0 -sticky nsw -pady 1
    set values {Low Medium High Max}  
    grid [ttk::combobox $frame.quality.comboqual -width 8 -values $values -state readonly -textvariable QWIKMD::basicGui(quality) -justify left] -row 0 -column 1 -sticky nsw -pady 1 -padx 1
    set QWIKMD::basicGui(quality) Low
    bind $frame.quality.comboqual <<ComboboxSelected>> {
       QWIKMD::RenderChgResolution
        %W selection clear
    }
    QWIKMD::balloon $frame.quality.comboqual [QWIKMD::renderRendBL]


    grid [ttk::frame $frame.header ] -row 0 -column 2 -sticky nse -pady 1 -padx 1 
    grid columnconfigure $frame.header 0 -weight 1

    QWIKMD::createInfoButton $frame.header 0 1
    bind $frame.header.info <Button-1> {
        set val [QWIKMD::renderInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow renderInfo [lindex $val 0] [lindex $val 2]
    }
}
#############################################
## Change resolution of the representations
#############################################
proc QWIKMD::RenderChgResolution {} {
    set repnum 0
    if {$QWIKMD::topMol != "" && $QWIKMD::topMol == [molinfo top]} {
        set repnum [molinfo $QWIKMD::topMol get numreps]
    }
    set scl 1
    set qcksind 0
    set qcksres 1
    switch $QWIKMD::basicGui(quality) {
        Medium {
            set scl 1.3
            set qcksind 1
            set qcksres 0.8
        }
        High {
            set scl 1.6
            set qcksind 2
            set qcksres 0.7
        }
        Max {
            set scl 2.0
            set qcksind 3
            set qcksres 0.50
        }
    }
    set NC "NewCartoon 0.300000 [expr 12.000000 * $scl] 4.500000 0"
    set QS "QuickSurf 1.000000 0.500000 $qcksres $qcksind"
    set LC "Licorice 0.300000 [expr 12.000000 * $scl] [expr 12.000000 * $scl]"
    set VDW "VDW 1.000000 [expr 12.000000 * $scl]"
    set Beads "Beads 1.000000 [expr 12.000000 * $scl]"
    set DB "DynamicBonds 2.0 0.300000 [expr 12.000000 * $scl]"
    set numreps [molinfo $QWIKMD::topMol get numreps]
    for {set repindex 0} {$repindex < $numreps} {incr repindex} {
        set replist [lindex [molinfo $QWIKMD::topMol get \"[list rep $repindex]\" ] 0]
        set style ""
        switch [lindex $replist 0] {
            NewCartoon {
                set style $NC
            }
            QuickSurf {
                set style $QS
            }
            Licorice {
                set style $LC
            }
            VDW {
                set style $VDW
            }
            Beads {
                set style $Beads
            }
            DynamicBonds {
                set style $DB
            }
        }
        if {$style != ""} {
            mol modstyle $repindex $QWIKMD::topMol $style
        }
    }
}
########################################
## Build Advanced analysis tabs
########################################
proc QWIKMD::AdvancedAnalyzeFrame {frame} {
    grid [ttk::frame $frame.fp ] -row 0 -column 0 -sticky nsew -pady 2 -padx 2 
    grid columnconfigure $frame.fp 0 -weight 1
    grid rowconfigure $frame.fp 0 -weight 0
    grid rowconfigure $frame.fp 2 -weight 2
    set row 0
    grid [ttk::frame $frame.fp.general -relief groove] -row $row -column 0 -sticky nsew -pady 2 -padx 2 
    grid columnconfigure $frame.fp.general 0 -weight 1

    grid [ttk::frame $frame.fp.general.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.fp.general.header 0 -weight 1
    
    grid [ttk::frame $frame.fp.general.header.cmbbutt ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.fp.general.header.cmbbutt 0 -weight 1
    grid columnconfigure $frame.fp.general.header.cmbbutt 1 -weight 1
    grid columnconfigure $frame.fp.general.header.cmbbutt 2 -weight 1
    grid columnconfigure $frame.fp.general.header.cmbbutt 3 -weight 1

    grid [ttk::label $frame.fp.general.header.cmbbutt.lbtitle -text "Analysis"] -row 0 -column 0 -sticky w -pady 2 
    set values {"H Bonds" "SMD Forces" "RMSF" "SASA" "Contact Area" "QM Energies" "Specific Heat" "Temperature Distribution" "MB Energy Distribution" "Temperature Quench"}

    grid [ttk::combobox $frame.fp.general.header.cmbbutt.comboAn -values $values -width 22 -state readonly -textvariable QWIKMD::advGui(analyze,advance,calcombo)] -row 0 -column 1 -sticky w -pady 2 -padx 2
    bind $frame.fp.general.header.cmbbutt.comboAn <<ComboboxSelected>> {
        QWIKMD::AdvancedSelected
        %W selection clear
    }

    QWIKMD::balloon $frame.fp.general.header.cmbbutt.comboAn [QWIKMD::advcComboAnBL]

    set QWIKMD::advGui(analyze,advance,calcombo) "H Bonds"

    grid [ttk::button $frame.fp.general.header.cmbbutt.calculate -text "Calculate" -padding "2 2 2 2" -width 15 -command QWIKMD::CalcAdvcAnalyze] -row 0 -column 2 -sticky e -pady 2 -padx 2
    set QWIKMD::advGui(analyze,advance,calcbutton) $frame.fp.general.header.cmbbutt.calculate
    QWIKMD::createInfoButton $frame.fp.general.header.cmbbutt 0 3
    # bind $frame.fp.general.header.cmbbutt.info <Button-1> {
    #   set val [QWIKMD::advAnalysisInfo]
    #   set QWIKMD::link [lindex $val 1]
    #   QWIKMD::infoWindow advAnalysisInfo [lindex $val 0] [lindex $val 2]
    # }

    incr row
    grid [ttk::frame $frame.fp.general.header.fcolapse] -row 1 -column 0 -sticky news -pady 4 -padx 2 
    grid columnconfigure $frame.fp.general.header.fcolapse 0 -weight 1

    set QWIKMD::advGui(analyze,advanceframe) $frame.fp.general.header.fcolapse
    incr row
    
    grid [ttk::frame $frame.fp.plot ] -row $row -column 0 -sticky nsew -pady 4 -padx 2 
    grid columnconfigure $frame.fp.plot 0 -weight 1

    QWIKMD::plotframe $frame.fp.plot advance
    QWIKMD::AdvancedSelected    
}
##############################################
## Command triggered by the calculate button of
## Advanced Analysis Frame
##############################################
proc QWIKMD::CalcAdvcAnalyze {} {
    set tabid [lindex [lindex $QWIKMD::selnotbooks 0] 1]
    if {$QWIKMD::basicGui(live,$tabid) == 1 && $QWIKMD::load == 0 && $QWIKMD::advGui(analyze,advance,calcombo) != "H Bonds" && $QWIKMD::advGui(analyze,advance,calcombo) != "SMD Forces"} {
        tk_messageBox -message "This option is only available after loading simulation results (load QwikMD input file *.qwikmd)"\
         -title "Calculation Not Available" -icon warning -parent $QWIKMD::topGui
        return
    }
    if {$QWIKMD::sasarep != ""} {
        mol delrep [QWIKMD::getrepnum $QWIKMD::sasarep] $QWIKMD::topMol
        set QWIKMD::sasarep ""
    }
    if {$QWIKMD::sasarepTotal1 != ""} {
        mol delrep [QWIKMD::getrepnum $QWIKMD::sasarepTotal1] $QWIKMD::topMol
        set QWIKMD::sasarepTotal1 ""
    }
    if {$QWIKMD::sasarepTotal2 != ""} {
        mol delrep [QWIKMD::getrepnum $QWIKMD::sasarepTotal2] $QWIKMD::topMol
        set QWIKMD::sasarepTotal2 ""
    }
    foreach m [molinfo list] {
        if {[string compare [molinfo $m get name] "{Color Scale Bar}"] == 0} {
          mol delete $m
        }
    }
    if {$QWIKMD::hbondsrepname != ""} {
        mol delrep [QWIKMD::getrepnum $QWIKMD::hbondsrepname] $QWIKMD::topMol
        set QWIKMD::hbondsrepname ""
    }
    switch  $QWIKMD::advGui(analyze,advance,calcombo) {
        
        "H Bonds" {
            QWIKMD::callhbondsCalcProc
        }
        "SMD Forces" {
            QWIKMD::callSmdCalc
        }
        "RMSF" {
            QWIKMD::RMSFCalc
        }
        "SASA" {
            QWIKMD::callSASA
        }
        "Contact Area" {
            QWIKMD::callCSASA
        }
        "QM Energies" {
            QWIKMD::callQMEnergies
        }
        "Specific Heat" {
            QWIKMD::SpecificHeatCalc
        }
        "Temperature Distribution" {
            QWIKMD::TempDistCalc
        }
        "MB Energy Distribution" {
            QWIKMD::MBCalC
        }
        "Temperature Quench" {
            QWIKMD::QTempCalc
        }   
    }
}
###################################################
## Command triggered by the combobox to select the
## analysis of the "Advanced Analysis" 
###################################################
proc QWIKMD::AdvancedSelected {} {
    if {[winfo exists $QWIKMD::advGui(analyze,advanceframe).header]} {
        destroy $QWIKMD::advGui(analyze,advanceframe).header
    }
    set infobut $QWIKMD::topGui.nbinput.f4.fp.general.header.cmbbutt.info
    switch $QWIKMD::advGui(analyze,advance,calcombo) {
        "H Bonds" {
            QWIKMD::HBFrame
            bind $infobut <Button-1> {
                set val [QWIKMD::hbondInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow hbondInfo [lindex $val 0] [lindex $val 2]
            }
        }
        "SMD Forces" {
            QWIKMD::SMDFrame
            bind $infobut <Button-1> {
                set val [QWIKMD::smdPlotInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow smdPlotInfo [lindex $val 0] [lindex $val 2]
            }
        }
        "RMSF" {
            QWIKMD::RMSFFrame
            bind $infobut <Button-1> {
                set val [QWIKMD::rmsfInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow rmsfInfo [lindex $val 0] [lindex $val 2]
            }
        }
        "SASA" {
            QWIKMD::SASAFrame noncontact
            bind $infobut <Button-1> {
                set val [QWIKMD::sasaPlotInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow sasaPlotInfo [lindex $val 0] [lindex $val 2]
            }
        }
        "Contact Area" {
            QWIKMD::SASAFrame contact
            bind $infobut <Button-1> {
                set val [QWIKMD::nscaPlotInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow nscaPlotInfo [lindex $val 0] [lindex $val 2]
            }
        }
        "QM Energies" {
            QWIKMD::QMEnergiesFrame
            bind $infobut <Button-1> {
                set val [QWIKMD::qmPlotInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow qmPlotInfo [lindex $val 0] [lindex $val 2]
            }
        }
        "Specific Heat" {
            QWIKMD::SpecificHeatFrame
            bind $infobut <Button-1> {
                set val [QWIKMD::specificHeatPlotInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow specificHeatPlotInfo [lindex $val 0] [lindex $val 2]
            }
        }
        "Temperature Distribution" {
            QWIKMD::TDistFrame
            bind $infobut <Button-1> {
                set val [QWIKMD::tempDistPlotInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow tempDistPlotInfo [lindex $val 0] [lindex $val 2]
            }
        }
        "Temperature Quench" {
            QWIKMD::TQuenchFrame
            bind $infobut <Button-1> {
                set val [QWIKMD::tQuenchPlotInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow tQuenchPlotInfo [lindex $val 0] [lindex $val 2]
            }
        }
        "MB Energy Distribution" {
            QWIKMD::MBDistributionFrame
            bind $infobut <Button-1> {
                set val [QWIKMD::mbDistributionPlotInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow mbDistributionPlotInfo [lindex $val 0] [lindex $val 2]
            }
        }

    }
}
###################################################
## Build the each analysis frame to be displayed on
## Advanced Analysis tab 
###################################################
proc QWIKMD::HBFrame {} {


    set frame $QWIKMD::advGui(analyze,advanceframe)
    grid [ttk::frame $frame.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header 0 -weight 1
    
    grid [ttk::frame $frame.header.optframe] -row 0 -column 0 -sticky nswe

    grid columnconfigure $frame.header.optframe 0 -weight 1
    grid columnconfigure $frame.header.optframe 1 -weight 1
    grid columnconfigure $frame.header.optframe 2 -weight 1

    grid [ttk::radiobutton $frame.header.optframe.intra -text "Within Solute" -variable QWIKMD::hbondssel -value "intra"] -row 0 -column 1 -sticky nsw -pady 2 -padx 4 
    grid [ttk::radiobutton $frame.header.optframe.inter -text "Between Solute\nand Solvent" -variable QWIKMD::hbondssel -value "inter"] -row 0 -column 2 -sticky nsw -pady 2 -padx 4
    grid [ttk::radiobutton $frame.header.optframe.sel -text "Between Selections" -variable QWIKMD::hbondssel -value "sel"] -row 0 -column 3 -sticky nsw -pady 2 -padx 4

    QWIKMD::balloon $frame.header.optframe.intra [QWIKMD::hbondsSelWithinBL]
    QWIKMD::balloon $frame.header.optframe.inter [QWIKMD::hbondsSelintraBL]
    QWIKMD::balloon $frame.header.optframe.sel [QWIKMD::hbondsSelBetwSelBL]

    set QWIKMD::advGui(analyze,advance,interradio) $frame.header.optframe.inter
    grid [ttk::frame $frame.header.selection] -row 1 -column 0 -sticky nswe

    grid columnconfigure $frame.header.selection 1 -weight 1

    ttk::style configure hBondSel1.TEntry -foreground $QWIKMD::tempEntry

    grid [ttk::label $frame.header.selection.sel1 -text "Selection 1"] -row 0 -column 0 -sticky w
    grid [ttk::entry $frame.header.selection.entrysel1 -style hBondSel1.TEntry -textvariable QWIKMD::advGui(analyze,advance,hbondsel1entry) -validate focus -validatecommand {
        QWIKMD::checkSelection %W hBondSel1.TEntry
        set QWIKMD::hbondssel "sel"
        return 1
    }] -row 0 -column 1 -sticky ew -padx 2
    set QWIKMD::advGui(analyze,advance,hbondsel1entry) "Type Selection"
    ttk::style configure hBondSel2.TEntry -foreground $QWIKMD::tempEntry

    grid [ttk::label $frame.header.selection.sel2 -text "Selection 2"] -row 1 -column 0 -sticky w
    grid [ttk::entry $frame.header.selection.entrysel2 -style hBondSel2.TEntry -textvariable QWIKMD::advGui(analyze,advance,hbondsel2entry) -validate focus -validatecommand {
        QWIKMD::checkSelection %W hBondSel2.TEntry
        set QWIKMD::hbondssel "sel"
        if {$QWIKMD::advGui(analyze,advance,hbondsel1entry) == "Type Selection"} {
            set QWIKMD::advGui(analyze,advance,hbondsel1entry) "protein"
        }
        return 1
    }] -row 1 -column 1 -sticky ew -padx 2
    set QWIKMD::advGui(analyze,advance,hbondsel2entry) "Type Selection"
    set tabid [lindex [lindex $QWIKMD::selnotbooks 0] 1] 
    if {$tabid == 1} {
        if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Implicit" || $QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Vacuum" } {
            $frame.header.optframe.inter configure -state disabled
        } else {
            $frame.header.optframe.inter configure -state normal
        }
    } else {
        if {$QWIKMD::basicGui(solvent,$QWIKMD::run,0) == "Implicit"} {
            $frame.header.optframe.inter configure -state disabled
        } else {
            $frame.header.optframe.inter configure -state normal
        }
    }

    QWIKMD::balloon $frame.header.selection.entrysel1 [QWIKMD::hbondsSelWithinBL]
    QWIKMD::balloon $frame.header.selection.entrysel2 [QWIKMD::hbondsSelintraBL]
}


proc QWIKMD::SMDFrame {} {

    set frame $QWIKMD::advGui(analyze,advanceframe)
    grid [ttk::frame $frame.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header 0 -weight 1
    
    grid [ttk::frame $frame.header.optframe] -row 0 -column 0 -sticky nswe

    grid columnconfigure $frame.header.optframe 0 -weight 1
    grid columnconfigure $frame.header.optframe 1 -weight 1
    

    grid [ttk::label $frame.header.optframe.label -text "X Axis\nUnists"] -row 0 -column 0 -sticky nsw -pady 2 -padx 4 
    
    grid [ttk::radiobutton $frame.header.optframe.ft -text "Force vs Time" -variable QWIKMD::smdxunit -value "time" -command {
        if {$QWIKMD::smdGui != ""} {
            set QWIKMD::timeXsmd ""
            set QWIKMD::smdvals ""
            set QWIKMD::smdvalsavg ""
            $QWIKMD::smdGui configure -xlabel "Time (ns)" -title "Force vs Time"
            QWIKMD::callSmdCalc
        }
        }] -row 0 -column 1 -sticky nsw -pady 2 -padx 4 

    QWIKMD::balloon $frame.header.optframe.ft [QWIKMD::smdForceTimeBL]

    grid [ttk::radiobutton $frame.header.optframe.trace -text "Force vs Distance" -variable QWIKMD::smdxunit -value "distance" -command {
        if {$QWIKMD::smdGui != ""} {
            set QWIKMD::timeXsmd ""
            set QWIKMD::smdvals ""
            set QWIKMD::smdvalsavg ""
            $QWIKMD::smdGui configure -xlabel "Distance (A)" -title "Force vs Distance"
            QWIKMD::callSmdCalc
        }
        }] -row 0 -column 2 -sticky nsw -pady 2 -padx 4

    QWIKMD::balloon $frame.header.optframe.trace [QWIKMD::smdForceDistanceBL]
}

proc QWIKMD::QMEnergiesFrame {} {
    set frame $QWIKMD::advGui(analyze,advanceframe)
    grid [ttk::frame $frame.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header 0 -weight 1

    grid [ttk::frame $frame.header.tableframeptcl] -row 0 -column 0 -sticky nswe -padx 4

    grid columnconfigure $frame.header.tableframeptcl 0 -weight 1
    grid rowconfigure $frame.header.tableframeptcl 0 -weight 1

    set table [QWIKMD::addSelectTable $frame.header.tableframeptcl 2]
    set QWIKMD::advGui(analyze,advance,qmprtcltbl) $table
    if {$QWIKMD::run == "QM/MM"} {
        for {set ptcl 0} {$ptcl < [llength $QWIKMD::confFile]} {incr ptcl} {
            $table insert end "{} {}"
            $table cellconfigure end,1 -text [lindex $QWIKMD::confFile $ptcl]
            $table cellconfigure end,0 -window QWIKMD::ProcSelect
        }
    }
    $table columnconfigure 1 -title "Protocol" -name QMRegion

    grid [ttk::frame $frame.header.tableframe] -row 1 -column 0 -sticky nswe -padx 4 -pady 2

    grid columnconfigure $frame.header.tableframe 0 -weight 1
    grid rowconfigure $frame.header.tableframe 0 -weight 1

    set table [QWIKMD::addSelectTable $frame.header.tableframe 3]
    set QWIKMD::advGui(analyze,advance,qmenertbl) $table
    if {$QWIKMD::run == "QM/MM"} {
        for {set qmID 1} {$qmID <= [$QWIKMD::advGui(qmtable) size]} {incr qmID} {
            $table insert end "{} {} {}"
            $table cellconfigure end,1 -text $qmID
            $table cellconfigure end,2 -text [$QWIKMD::advGui(qmtable) cellcget [expr $qmID -1],1 -text]
            $table cellconfigure end,0 -window QWIKMD::ProcSelect
        }
    }
    $table columnconfigure 1 -title "QM Region" -name QMRegion
    $table columnconfigure 2 -title "n Atoms" -name nAtoms


    grid [ttk::frame $frame.header.optframe] -row 2 -column 0 -sticky nswe -padx 4
    grid columnconfigure $frame.header.optframe 0 -weight 1

    grid columnconfigure $frame.header.optframe 0 -weight 1
    grid columnconfigure $frame.header.optframe 1 -weight 1
    
}

proc QWIKMD::RMSFFrame {} {
    set row 0
    set frame $QWIKMD::advGui(analyze,advanceframe)
    grid [ttk::frame $frame.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header 0 -weight 1
    
    
    grid [ttk::frame $frame.header.optframe] -row $row -column 0 -sticky nswe -pady 5
    incr row
    grid columnconfigure $frame.header.optframe 0 -weight 0
    grid columnconfigure $frame.header.optframe 1 -weight 1

    ttk::style configure RmsfSel.TEntry -foreground $QWIKMD::tempEntry
    grid [ttk::label $frame.header.optframe.lbor -text "Atom Selection: "] -row 0 -column 0 -sticky w -padx 2

    grid [ttk::entry $frame.header.optframe.entry -style RmsfSel.TEntry -textvariable QWIKMD::advGui(analyze,advance,rmsfselentry) -validate focus -validatecommand {
        QWIKMD::checkSelection %W RmsfSel.TEntry
        return 1
    }] -row 0 -column 1 -sticky ew -padx 2
    set QWIKMD::advGui(analyze,advance,rmsfselentry) "protein"

    QWIKMD::balloon $frame.header.optframe.entry [QWIKMD::rmsfGeneralSelectionBL]

    grid [ttk::frame $frame.header.align] -row $row -column 0 -sticky nswe -pady 5
    incr row
    grid columnconfigure $frame.header.align 3 -weight 1


    grid [ttk::checkbutton $frame.header.align.cAlign -text "Align Structure" -variable QWIKMD::advGui(analyze,advance,rmsfalicheck)] -row 0 -column 0 -sticky nsw -padx 2
    set QWIKMD::advGui(analyze,advance,rmsfalicheck) 0

    QWIKMD::balloon $frame.header.align.cAlign [QWIKMD::rmsfAlignBL]

    set values {"Backbone" "Alpha Carbon" "No Hydrogen" "All"}
    grid [ttk::combobox $frame.header.align.combo -values $values -width 12 -state readonly  -exportselection 0] -row 0 -column 1 -sticky nsw -padx 2
    $frame.header.align.combo set "Backbone"
    set QWIKMD::advGui(analyze,advance,rmsfaligncomb) "backbone"
    bind $frame.header.align.combo <<ComboboxSelected>> {
        set text [%W get]
        switch  $text {
            Backbone {
                set QWIKMD::advGui(analyze,advance,rmsfaligncomb) "backbone"
            }
            "Alpha Carbon" {
                set QWIKMD::advGui(analyze,advance,rmsfaligncomb) "alpha carbon"
            }
            "No Hydrogen" {
                set QWIKMD::advGui(analyze,advance,rmsfaligncomb) "noh"
            }
            "All" {
                set QWIKMD::advGui(analyze,advance,rmsfaligncomb) "all"
            }
            
        }
        %W selection clear
    }

    QWIKMD::balloon $frame.header.align.combo [QWIKMD::rmsfAlignSelection]

    grid [ttk::label $frame.header.align.lbor -text "or"] -row 0 -column 2 -sticky w -padx 5

    ttk::style configure RmsfSel.TEntry -foreground $QWIKMD::tempEntry
    grid [ttk::entry $frame.header.align.entry -style RmfdSel.TEntry -textvariable QWIKMD::advGui(analyze,advance,rmsfalignsel) -validate focus -validatecommand {
        QWIKMD::checkSelection %W RmfdSel.TEntry
        return 1
    }] -row 0 -column 3 -sticky ew -padx 2
    set QWIKMD::advGui(analyze,advance,rmsfalignsel) "Type Selection"

    QWIKMD::balloon $frame.header.align.entry [QWIKMD::rmsfGeneralAlignSelectionBL] 

    grid [ttk::frame $frame.header.frames] -row $row -column 0 -sticky nswe -pady 5
    incr row

    grid columnconfigure $frame.header.frames 2 -weight 1
    grid columnconfigure $frame.header.frames 4 -weight 1

    grid [ttk::label $frame.header.frames.ltext -text "Frame Selection:"] -row 0 -column 0 -sticky w -padx 2

    set QWIKMD::advGui(analyze,advance,rmsffrom) 0
    set QWIKMD::advGui(analyze,advance,rmsfto) 1
    if {$QWIKMD::load == 1} {
        set QWIKMD::advGui(analyze,advance,rmsfto) [expr [molinfo $QWIKMD::topMol get numframes] -1]
    }
    set QWIKMD::advGui(analyze,advance,rmsfskip) 1

    grid [ttk::label $frame.header.frames.lfrom -text "From:"] -row 0 -column 1 -sticky w -padx 2
    grid [ttk::entry $frame.header.frames.entryfrom -textvariable QWIKMD::advGui(analyze,advance,rmsffrom) -width 8 -validate focus -validatecommand {
        if {[string is integer -strict $QWIKMD::advGui(analyze,advance,rmsffrom)] == 0} {
            set QWIKMD::advGui(analyze,advance,rmsffrom) 0
        }
        if {$QWIKMD::advGui(analyze,advance,rmsfto) <= $QWIKMD::advGui(analyze,advance,rmsffrom)} {
            if {$QWIKMD::advGui(analyze,advance,rmsffrom) == [expr [molinfo $QWIKMD::topMol get numframes] -1] } {
                incr QWIKMD::advGui(analyze,advance,rmsffrom) -1
            } else {
                incr QWIKMD::advGui(analyze,advance,rmsfto)
            }
        }
        return 1
    }] -row 0 -column 2 -sticky we -padx 1
    set QWIKMD::advGui(analyze,advance,rmsffrom) 0

    QWIKMD::balloon $frame.header.frames.entryfrom [QWIKMD::rmsfInitFrameBL]

    grid [ttk::label $frame.header.frames.lto -text "To:"] -row 0 -column 3 -sticky w -padx 1
    grid [ttk::entry $frame.header.frames.entryto -textvariable QWIKMD::advGui(analyze,advance,rmsfto) -width 8  -validate focus -validatecommand {
        if {[string is integer -strict $QWIKMD::advGui(analyze,advance,rmsfto)] == 0} {
            set QWIKMD::advGui(analyze,advance,rmsfto)  [expr [molinfo $QWIKMD::topMol get numframes] -1]
        }
        
        if {$QWIKMD::advGui(analyze,advance,rmsfto) <= $QWIKMD::advGui(analyze,advance,rmsffrom) } {
            if {$QWIKMD::advGui(analyze,advance,rmsffrom) == [expr [molinfo $QWIKMD::topMol get numframes] -1] } {
                incr QWIKMD::advGui(analyze,advance,rmsffrom) -1
            } else {
                incr QWIKMD::advGui(analyze,advance,rmsfto)
            }
        }
        return 1
    }] -row 0 -column 4 -sticky we -padx 1
    if {$QWIKMD::load == 1} {
        set QWIKMD::advGui(analyze,advance,rmsfto) [expr [molinfo $QWIKMD::topMol get numframes] -1]
    }

    QWIKMD::balloon $frame.header.frames.entryto [QWIKMD::rmsfFinalFrameBL]

    grid [ttk::label $frame.header.frames.lskip -text "Skip:"] -row 0 -column 5 -sticky w -padx 1
    grid [ttk::entry $frame.header.frames.entryskip -textvariable QWIKMD::advGui(analyze,advance,rmsfskip) -width 8 -validate focus -validatecommand {
        if {[string is integer -strict $QWIKMD::advGui(analyze,advance,rmsfskip)] == 0} {
            set QWIKMD::advGui(analyze,advance,rmsfskip) 1
        }
        if {$QWIKMD::advGui(analyze,advance,rmsfskip) <= 0 || $QWIKMD::advGui(analyze,advance,rmsfskip) == ""} {
            set QWIKMD::advGui(analyze,advance,rmsfskip) 1
        }
        return 1
    }] -row 0 -column 6 -sticky w -padx 1
    set QWIKMD::advGui(analyze,advance,rmsfskip) 1

    incr row
    grid [ttk::frame $frame.header.rep] -row $row -column 0 -sticky nswe -pady 5

    QWIKMD::balloon $frame.header.frames.entryskip [QWIKMD::rmsfSkipFrameBL]

    grid columnconfigure $frame.header.rep 1 -weight 1
    grid columnconfigure $frame.header.rep 2 -weight 1

    grid [ttk::label $frame.header.rep.lrep -text "Representation"] -row 0 -column 0 -sticky w -padx 2
    set rep "Off NewCartoon QuickSurf Licorice VDW Lines Beads Points"
    grid [ttk::combobox $frame.header.rep.repcmb -values $rep -textvariable QWIKMD::advGui(analyze,advance,rmsfrep) -state readonly] -row 0 -column 1 -sticky w -padx 2
    set QWIKMD::advGui(analyze,advance,rmsfrep) NewCartoon
    bind $frame.header.rep.repcmb <<ComboboxSelected>> {
        if {$QWIKMD::rmsfrep != ""} {
            set rep $QWIKMD::advGui(analyze,advance,rmsfrep)
            mol modstyle [QWIKMD::getrepnum $QWIKMD::rmsfrep] $QWIKMD::topMol $rep
            QWIKMD::RenderChgResolution
        }
        %W selection clear  
    }

    QWIKMD::balloon $frame.header.rep.repcmb [QWIKMD::rmsfRepBL]
}
##############################################
## Surface calculation frames.
## opt == contact - "Contact Area"
## opt == noncontact - SASA
##############################################
proc QWIKMD::SASAFrame {opt} {
    set row 0
    set frame $QWIKMD::advGui(analyze,advanceframe)
    grid [ttk::frame $frame.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header 0 -weight 1
    
    grid [ttk::frame $frame.header.optframe] -row $row -column 0 -sticky nswe -pady 5
    incr row
    grid columnconfigure $frame.header.optframe 0 -weight 0
    grid columnconfigure $frame.header.optframe 1 -weight 1

    set lbltext "Atom Selection: "
    if {$opt == "contact"} {
        set lbltext "Selection 1: "
    }
    grid [ttk::label $frame.header.optframe.lsel -text $lbltext] -row 0 -column 0 -sticky w -padx 2

    ttk::style configure SASASel.TEntry -foreground $QWIKMD::tempEntry
    grid [ttk::entry $frame.header.optframe.entry -style SASASel.TEntry -textvariable QWIKMD::advGui(analyze,advance,sasaselentry) -validate focus -validatecommand {
        QWIKMD::checkSelection %W SASASel.TEntry
        return 1
    }] -row 0 -column 1 -sticky ew -padx 2
    set QWIKMD::advGui(analyze,advance,sasaselentry) "protein"
    if {$opt == "noncontact"} {
        QWIKMD::balloon $frame.header.optframe.entry [QWIKMD::sasaSel1BL]
    } else {
        QWIKMD::balloon $frame.header.optframe.entry [QWIKMD::sasaSel1ContactBL]
    }
    set lbltext "Restriction Selection: "
    if {$opt == "contact"} {
        set lbltext "Selection 2: "
    }
    grid [ttk::label $frame.header.optframe.lrestsel -text $lbltext] -row 1 -column 0 -sticky w -padx 2

    ttk::style configure SASARestSel.TEntry -foreground $QWIKMD::tempEntry
    grid [ttk::entry $frame.header.optframe.restentry -style SASARestSel.TEntry -textvariable QWIKMD::advGui(analyze,advance,sasarestselentry) -validate focus -validatecommand {
        QWIKMD::checkSelection %W SASARestSel.TEntry
        return 1
    }] -row 1 -column 1 -sticky ew -padx 2
    set QWIKMD::advGui(analyze,advance,sasarestselentry) "Type Selection"


    if {$opt == "noncontact"} {
        QWIKMD::balloon $frame.header.optframe.restentry [QWIKMD::sasaSel2BL]
    } else {
        QWIKMD::balloon $frame.header.optframe.restentry [QWIKMD::sasaSel2ContactBL]
    }
    grid [ttk::frame $frame.header.rep] -row $row -column 0 -sticky news
    incr row

    grid [ttk::label $frame.header.rep.lrep -text "Representation"] -row 0 -column 0 -sticky w -padx 2
    set rep "Off NewCartoon QuickSurf Surf Licorice VDW Lines Beads Points"
    grid [ttk::combobox $frame.header.rep.repcmb -values $rep -textvariable QWIKMD::advGui(analyze,advance,sasarep) -state readonly] -row 0 -column 1 -sticky w -padx 2
    set QWIKMD::advGui(analyze,advance,sasarep) NewCartoon
    bind $frame.header.rep.repcmb <<ComboboxSelected>> {
        if {$QWIKMD::sasarep != ""} {
            set rep $QWIKMD::advGui(analyze,advance,sasarep)
            mol modstyle [QWIKMD::getrepnum $QWIKMD::sasarep] $QWIKMD::topMol $rep
            QWIKMD::RenderChgResolution
        }
        %W selection clear  
    }

    QWIKMD::balloon $frame.header.rep.repcmb [QWIKMD::sasaRepBL]

    grid [ttk::frame $frame.header.tbframe] -row $row -column 0 -sticky news
    incr row

    grid columnconfigure $frame.header.tbframe 0 -weight 1

    option add *Tablelist.activeStyle       frame
    
    set fro2 $frame.header.tbframe

    option add *Tablelist.movableColumns    no
    option add *Tablelist.labelCommand      tablelist::sortByColumn


        tablelist::tablelist $fro2.tb -columns {\
            0 "Res ID" center
            0 "Res NAME" center
            0 "Chain" center
            0 "SASA Avg(A\u00b2)" center
            0 "STDV" center
        }\
        -yscrollcommand [list $fro2.scr1 set] -xscrollcommand [list $fro2.scr2 set] \
                -showseparators 0 -labelrelief groove  -labelbd 1 -selectforeground black\
                -foreground black -background white -state normal -selectmode extended -height 10 -stretch all -stripebackgroun white -exportselection true\
                

    $fro2.tb columnconfigure 0 -selectbackground cyan -sortmode dictionary -name ResdID -maxwidth 0
    $fro2.tb columnconfigure 1 -selectbackground cyan -sortmode dictionary -name ResdName -maxwidth 0
    $fro2.tb columnconfigure 2 -selectbackground cyan -sortmode dictionary -name Chain -maxwidth 0
    $fro2.tb columnconfigure 3 -selectbackground cyan -sortmode real -name Average -maxwidth 0
    $fro2.tb columnconfigure 4 -selectbackground cyan -sortmode real -name STDV -maxwidth 0

    grid $fro2.tb -row 0 -column 0 -sticky news 

    ##Scrool_BAr V
    scrollbar $fro2.scr1 -orient vertical -command [list $fro2.tb  yview]
     grid $fro2.scr1 -row 0 -column 1  -sticky ens

    ## Scrool_Bar H
    scrollbar $fro2.scr2 -orient horizontal -command [list $fro2.tb xview]
    grid $fro2.scr2 -row 1 -column 0 -sticky swe

    set QWIKMD::advGui(analyze,advance,sasatb) $fro2.tb

    bind $fro2.tb <<TablelistSelect>>  {
        set sasaind [%W curselection]
        set index [list]
        if {$sasaind != ""} {
            if {$QWIKMD::sasarepTotal1 != ""} {
                mol delrep [QWIKMD::getrepnum $QWIKMD::sasarepTotal1] $QWIKMD::topMol
                set QWIKMD::sasarepTotal1 ""
            }
            if {$QWIKMD::sasarepTotal2 != ""} {
                mol delrep [QWIKMD::getrepnum $QWIKMD::sasarepTotal2] $QWIKMD::topMol
                set QWIKMD::sasarepTotal2 ""
            }
            foreach tbindex $sasaind {
                set compresid [%W cellcget $tbindex,0 -text] 
                set compchain [%W cellcget $tbindex,2 -text]
                if {[string match "*Total*" $compchain ] > 0} {
                    switch $QWIKMD::advGui(analyze,advance,calcombo) {
                        "SASA" {
                            set restrict $QWIKMD::advGui(analyze,advance,sasarestselentry)
                            if {$QWIKMD::advGui(analyze,advance,sasarestselentry) == "Type Selection" || $QWIKMD::advGui(analyze,advance,sasarestselentry) == ""} {
                                set restrict $QWIKMD::advGui(analyze,advance,sasaselentry)
                            }
                            mol addrep $QWIKMD::topMol
                            set QWIKMD::sasarepTotal1 [mol repname $QWIKMD::topMol [expr [molinfo $QWIKMD::topMol get numreps] -1] ]
                            mol modcolor [QWIKMD::getrepnum $QWIKMD::sasarepTotal1] $QWIKMD::topMol "User"
                            mol modselect [QWIKMD::getrepnum $QWIKMD::sasarepTotal1] $QWIKMD::topMol "\($QWIKMD::advGui(analyze,advance,sasaselentry)\) and \($restrict\)"
                            mol modstyle [QWIKMD::getrepnum $QWIKMD::sasarepTotal1] $QWIKMD::topMol "Surf"
                            mol selupdate [QWIKMD::getrepnum $QWIKMD::sasarepTotal1] $QWIKMD::topMol on
                        }
                        "Contact Area" {     
                            if {$compchain == "Total1_2"} {
                                mol addrep $QWIKMD::topMol
                                set globalsel "\($QWIKMD::advGui(analyze,advance,sasaselentry)\)"
                                set restrictsel "\(within 5 of \($QWIKMD::advGui(analyze,advance,sasarestselentry)\)\) and \($QWIKMD::advGui(analyze,advance,sasaselentry)\)"
                                set QWIKMD::sasarepTotal1 [mol repname $QWIKMD::topMol [expr [molinfo $QWIKMD::topMol get numreps] -1] ]
                                mol modcolor [QWIKMD::getrepnum $QWIKMD::sasarepTotal1] $QWIKMD::topMol "User"
                                mol modselect [QWIKMD::getrepnum $QWIKMD::sasarepTotal1] $QWIKMD::topMol "same residue as \(\($globalsel\) and \($restrictsel\)\)"
                                mol modstyle [QWIKMD::getrepnum $QWIKMD::sasarepTotal1] $QWIKMD::topMol "Surf"
                                mol selupdate [QWIKMD::getrepnum $QWIKMD::sasarepTotal1] $QWIKMD::topMol on
                            }
                            if {$compchain == "Total2_1"} {
                                mol addrep $QWIKMD::topMol
                                set globalsel "\($QWIKMD::advGui(analyze,advance,sasarestselentry)\)"
                                set restrictsel "\(within 5 of \($QWIKMD::advGui(analyze,advance,sasaselentry)\)\) and \($QWIKMD::advGui(analyze,advance,sasarestselentry)\)"
                                set QWIKMD::sasarepTotal2 [mol repname $QWIKMD::topMol [expr [molinfo $QWIKMD::topMol get numreps] -1] ]
                                mol modcolor [QWIKMD::getrepnum $QWIKMD::sasarepTotal2] $QWIKMD::topMol "User"
                                mol modselect [QWIKMD::getrepnum $QWIKMD::sasarepTotal2] $QWIKMD::topMol "same residue as \(\($globalsel\) and \($restrictsel\)\)"
                                mol modstyle [QWIKMD::getrepnum $QWIKMD::sasarepTotal2] $QWIKMD::topMol "Surf"
                                mol selupdate [QWIKMD::getrepnum $QWIKMD::sasarepTotal2] $QWIKMD::topMol on
                            }
                        }

                    }
                    continue
                } 
                set residids [$QWIKMD::selresTable searchcolumn 0 $compresid -all]
                set lines [$QWIKMD::selresTable get $residids]
                if {[llength [lindex $lines 0] ] == 1} {
                    set lines [list $lines]
                }
                set residids [$QWIKMD::selresTable searchcolumn 0 $compresid -all]
                set lines [$QWIKMD::selresTable get $residids]
                if {[llength [lindex $lines 0] ] == 1} {
                    set lines [list $lines]
                }
                lappend index [lindex $residids [lsearch -index 2 $lines $compchain]]
                
            }
            if {[llength $index] > 0} {
                $QWIKMD::selresTable selection set $index
               QWIKMD::selResidForSelection
                for {set i 1} {$i <= [llength $index]} { incr i} {
                    set repindex [expr [llength $QWIKMD::resrepname] - $i]
                    mol modcolor [QWIKMD::getrepnum [lindex [lindex $QWIKMD::resrepname $repindex] 1] ] $QWIKMD::topMol "User"
                    mol modstyle [QWIKMD::getrepnum [lindex [lindex $QWIKMD::resrepname $repindex] 1] ] $QWIKMD::topMol "Surf"
                }
            }
        }
        if {[llength $sasaind] > 0} {
            %W selection set $sasaind
        }
    }

    bind [$fro2.tb labeltag] <Any-Enter> {
        set col [tablelist::getTablelistColumn %W]
        set help 0
        switch $col {
            0 {
                set help [QWIKMD::ResidselTabelResidBL]
            }
            1 {
                set help [QWIKMD::ResidselTabelResnameBL]
            }
            2 {
                set help [QWIKMD::ResidselTabelChainBL]
            }
            3 {
                set help [QWIKMD::sasaTblSASABL]
            }
            4 {
                set help [QWIKMD::sasaTblSTDVBL]
            }
            default {
                set help $col
            }
        }
        after 1000 [list QWIKMD::balloon:show %W $help]
  
    }
    bind [$fro2.tb labeltag] <Any-Leave> "destroy %W.balloon"
}

proc QWIKMD::SpecificHeatFrame {} {
    set frame $QWIKMD::advGui(analyze,advanceframe)
    grid [ttk::frame $frame.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header 0 -weight 1

    grid [ttk::frame $frame.header.tableframe] -row 0 -column 0 -sticky nswe -padx 4

    grid columnconfigure $frame.header.tableframe 0 -weight 1
    grid rowconfigure $frame.header.tableframe 0 -weight 1

    set table [QWIKMD::addSelectTable $frame.header.tableframe 2]
    set QWIKMD::advGui(analyze,advance,SPH) $table
    if {$QWIKMD::confFile != ""} {
        for {set i 0} {$i < [llength $QWIKMD::confFile]} {incr i} {
            if {[file exists $QWIKMD::outPath/run/[lindex $QWIKMD::confFile $i].dcd ]} {
                $table insert end "{} {}"
                set QWIKMD::radiobtt [lindex $QWIKMD::confFile $i]
                $table cellconfigure end,1 -text [lindex $QWIKMD::confFile $i]
                $table cellconfigure end,0 -window QWIKMD::Select
            }
        }
    }

    
    grid [ttk::frame $frame.header.optframe] -row 1 -column 0 -sticky nswe -padx 4
    grid columnconfigure $frame.header.optframe 0 -weight 1

    grid [ttk::frame $frame.header.optframe.tmpconst] -row 0 -column 0 -sticky nswe -padx 4
    grid columnconfigure $frame.header.optframe.tmpconst 0 -weight 1

    grid [ttk::frame $frame.header.optframe.tmpconst.tmp] -row 0 -column 0 -sticky w -pady 2
    grid columnconfigure $frame.header.optframe.tmpconst.tmp 0 -weight 0

    grid [ttk::label $frame.header.optframe.tmpconst.tmp.lblTEMP -text "Temperature"] -row 0 -column 0 -sticky w
    grid [ttk::entry $frame.header.optframe.tmpconst.tmp.tempentry -textvariable QWIKMD::advGui(analyze,advance,tempentry) -width 5] -row 0 -column 1 -sticky w 
    grid [ttk::label $frame.header.optframe.tmpconst.tmp.lblTEMPunit -text "C"] -row 0 -column 2 -sticky w
    set QWIKMD::advGui(analyze,advance,tempentry) 27

    QWIKMD::balloon $frame.header.optframe.tmpconst.tmp.tempentry [QWIKMD::spcfHeatTempBL]

    grid [ttk::frame $frame.header.optframe.tmpconst.const] -row 0 -column 1 -sticky e -padx 4
    grid columnconfigure $frame.header.optframe.tmpconst.const 0 -weight 0
    grid [ttk::label $frame.header.optframe.tmpconst.const.lblBK -text "Boltzmann k"] -row 0 -column 0 -sticky e
    grid [ttk::entry $frame.header.optframe.tmpconst.const.bkentry -textvariable QWIKMD::advGui(analyze,advance,bkentry) -width 12] -row 0 -column 1 -sticky e 
    grid [ttk::label $frame.header.optframe.tmpconst.const.lblBKUnit -text "kcal/mol*K"] -row 0 -column 2 -sticky w
    set QWIKMD::advGui(analyze,advance,bkentry) 0.00198657

    QWIKMD::balloon $frame.header.optframe.tmpconst.const.bkentry [QWIKMD::spcfHeatBKBL]

    grid [ttk::frame $frame.header.optframe.sel] -row 1 -column 0 -sticky nswe -pady 4
    grid columnconfigure $frame.header.optframe.sel 1 -weight 1
    grid [ttk::label $frame.header.optframe.sel.lblsel -text "Selection"] -row 0 -column 0 -sticky w
    grid [ttk::entry $frame.header.optframe.sel.bkentrysel -textvariable QWIKMD::advGui(analyze,advance,selentry) -width 7] -row 0 -column 1 -sticky we -padx 2
    set QWIKMD::advGui(analyze,advance,selentry) all

    QWIKMD::balloon $frame.header.optframe.sel.bkentrysel [QWIKMD::spcfHeatSelBL]

    grid [ttk::frame $frame.header.optframe.output] -row 2 -column 0 -sticky we -pady 2
    grid columnconfigure $frame.header.optframe.output 0 -weight 0

    
    grid [ttk::label $frame.header.optframe.output.lblBK -text "Specific Heat Results:"] -row 0 -column 0 -sticky e

    grid [ttk::frame $frame.header.optframe.output.kcal] -row 1 -column 0 -sticky w -pady 4
    grid [ttk::label $frame.header.optframe.output.kcal.lbunit -text "kcal/mol*K"] -row 0 -column 0 -sticky w
    grid [ttk::entry $frame.header.optframe.output.kcal.entryval -textvariable QWIKMD::advGui(analyze,advance,kcal) -width 12] -row 0 -column 1 -sticky e -padx 2 
    
    QWIKMD::balloon $frame.header.optframe.output.kcal.entryval [QWIKMD::spcfHeatResKcalBL]

    grid [ttk::frame $frame.header.optframe.output.joul] -row 1 -column 1 -sticky w -pady 4
    grid [ttk::label $frame.header.optframe.output.joul.lbunit -text "J/kg*C"] -row 0 -column 0 -sticky w
    grid [ttk::entry $frame.header.optframe.output.joul.entryval -textvariable QWIKMD::advGui(analyze,advance,joul) -width 12] -row 0 -column 1 -sticky e -padx 2 
    
    QWIKMD::balloon $frame.header.optframe.output.joul.entryval [QWIKMD::spcfHeatResJoulBL]
}

proc QWIKMD::TDistFrame {} {
    set frame $QWIKMD::advGui(analyze,advanceframe)
    grid [ttk::frame $frame.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header 0 -weight 1

    grid [ttk::frame $frame.header.tableframe] -row 0 -column 0 -sticky nswe -padx 4

    grid columnconfigure $frame.header.tableframe 0 -weight 1
    grid rowconfigure $frame.header.tableframe 0 -weight 1

    set table [QWIKMD::addSelectTable  $frame.header.tableframe 2]
    set QWIKMD::advGui(analyze,advance,tdist) $table
    if {$QWIKMD::confFile != ""} {
        for {set i 0} {$i < [llength $QWIKMD::confFile]} {incr i} {
            if {[file exists $QWIKMD::outPath/run/[lindex $QWIKMD::confFile $i].dcd ]} {
                $table insert end "{} {}"
                set QWIKMD::radiobtt [lindex $QWIKMD::confFile $i]
                $table cellconfigure end,1 -text [lindex $QWIKMD::confFile $i]
                $table cellconfigure end,0 -window QWIKMD::Select
            }
        }
    }
    grid [ttk::frame $frame.header.optframe] -row 1 -column 0 -sticky nswe -padx 4
    grid columnconfigure $frame.header.optframe 1 -weight 1
    
    grid [ttk::label $frame.header.optframe.lblfitting -text "Curve fitting equation = "] -row 0 -column 0 -sticky w
    grid [ttk::entry $frame.header.optframe.fittingentry -state normal] -row 0 -column 1 -sticky we
    $frame.header.optframe.fittingentry delete 0 end
    $frame.header.optframe.fittingentry insert end "y= a0 * exp(-(x-a1)^2/a2)"
    $frame.header.optframe.fittingentry configure -state readonly

    QWIKMD::balloon $frame.header.optframe.fittingentry [QWIKMD::spcfTempDistEqBL]
}

proc QWIKMD::MBDistributionFrame {} {
    set frame $QWIKMD::advGui(analyze,advanceframe)
    grid [ttk::frame $frame.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header 0 -weight 1

    grid [ttk::frame $frame.header.tableframe] -row 0 -column 0 -sticky nswe -padx 4

    grid columnconfigure $frame.header.tableframe 0 -weight 1
    grid rowconfigure $frame.header.tableframe 0 -weight 1

    
    set table [QWIKMD::addSelectTable  $frame.header.tableframe 2]
    if {$QWIKMD::confFile != ""} {
        for {set i 0} {$i < [llength $QWIKMD::confFile]} {incr i} {
            if {[file exists $QWIKMD::outPath/run/[lindex $QWIKMD::confFile $i].dcd ]} {
                $table insert end "{} {}"
                set QWIKMD::radiobtt [lindex $QWIKMD::confFile $i]
                $table cellconfigure end,1 -text [lindex $QWIKMD::confFile $i]
                $table cellconfigure end,0 -window QWIKMD::Select
            }        
        }
    }
    grid [ttk::frame $frame.header.optframe] -row 1 -column 0 -sticky nswe -padx 4
    grid columnconfigure $frame.header.optframe 1 -weight 1

    grid [ttk::label $frame.header.optframe.lblatmsel -text "Atom selection : "] -row 0 -column 0 -sticky w
    grid [ttk::entry $frame.header.optframe.atmselentry -state normal -textvariable QWIKMD::advGui(analyze,advance,MBsel)] -row 0 -column 1 -sticky we
    set QWIKMD::advGui(analyze,advance,MBsel) all

    QWIKMD::balloon $frame.header.optframe.atmselentry [QWIKMD::mbDistSelBL]

    grid [ttk::label $frame.header.optframe.lblfitting -text "Curve fitting equation = "] -row 1 -column 0 -sticky w
    grid [ttk::entry $frame.header.optframe.fittingentry -state normal] -row 1 -column 1 -sticky we
    $frame.header.optframe.fittingentry delete 0 end
    $frame.header.optframe.fittingentry insert end "y = (2/ sqrt(Pi * a0^3)) * sqrt(x) * exp (-x / a0)"
    $frame.header.optframe.fittingentry configure -state readonly

    QWIKMD::balloon $frame.header.optframe.fittingentry [QWIKMD::mbDistEqBL]

}

proc QWIKMD::TQuenchFrame {} { 
    set frame $QWIKMD::advGui(analyze,advanceframe)
    grid [ttk::frame $frame.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header 0 -weight 1
    
    grid [ttk::frame $frame.header.tableframe] -row 0 -column 0 -sticky nswe -padx 4

    grid columnconfigure $frame.header.tableframe 0 -weight 1
    grid rowconfigure $frame.header.tableframe 0 -weight 1

    set table [QWIKMD::addSelectTable $frame.header.tableframe 3]

    # $table configure -editstartcommand QWIKMD::StartQTempstep -editendcommand QWIKMD::EndQTempstep -editselectedonly true
    
    set QWIKMD::advGui(analyze,advance,qtmeptbl) $table
    if {$QWIKMD::confFile != ""} {
        for {set i 0} {$i < [llength $QWIKMD::confFile]} {incr i} {
            if {[file exists $QWIKMD::outPath/run/[lindex $QWIKMD::confFile $i].dcd ]} {
                $table insert end "{} {} {}"
                $table cellconfigure end,0 -window QWIKMD::ProcSelect
                $table cellconfigure end,1 -text [lindex $QWIKMD::confFile $i]
                $table cellconfigure end,2 -text ""
            } 
        }   
    }

    grid [ttk::frame $frame.header.optframe] -row 1 -column 0 -sticky nswe -padx 4

    grid columnconfigure $frame.header.optframe 0 -weight 0
    grid columnconfigure $frame.header.optframe 1 -weight 0
    grid columnconfigure $frame.header.optframe 2 -weight 1
    grid columnconfigure $frame.header.optframe 3 -weight 0
    grid columnconfigure $frame.header.optframe 4 -weight 0
    grid columnconfigure $frame.header.optframe 5 -weight 0
    grid rowconfigure $frame.header.optframe 0 -weight 1

    grid [ttk::label $frame.header.optframe.lblACC -text "Autocorrelation\ndecay time"] -row 0 -column 0 -sticky w
    grid [ttk::entry $frame.header.optframe.entry -textvariable QWIKMD::advGui(analyze,advance,decayentry) -width 7] -row 0 -column 1 -sticky w -padx 2
    set QWIKMD::advGui(analyze,advance,decayentry) 2.4

    QWIKMD::balloon $frame.header.optframe.entry [QWIKMD::tempQAtcrrTimeBL]

    grid [ttk::label $frame.header.optframe.lblTEMP -text "Initial Temperature"] -row 0 -column 3 -sticky w
    grid [ttk::entry $frame.header.optframe.tempentry -textvariable QWIKMD::advGui(analyze,advance,tempentry) -width 7] -row 0 -column 4 -sticky w -padx 2
    grid [ttk::label $frame.header.optframe.lblTEMPunit -text "C"] -row 0 -column 5 -sticky w
    set QWIKMD::advGui(analyze,advance,tempentry) 27

    QWIKMD::balloon $frame.header.optframe.tempentry [QWIKMD::tempQInitTempBL]

    grid [ttk::label $frame.header.optframe.lblechodepth -text "Echo depth = "] -row 1 -column 0 -sticky w
    grid [ttk::label $frame.header.optframe.lblechodepthval ] -row 1 -column 1 -sticky w
    set QWIKMD::advGui(analyze,advance,echolb) $frame.header.optframe.lblechodepthval

    QWIKMD::balloon $frame.header.optframe.lblechodepthval [QWIKMD::tempQTempDepthBL]

    grid [ttk::label $frame.header.optframe.lblechoref -text "Echo time = "] -row 1 -column 3 -sticky w
    grid [ttk::label $frame.header.optframe.lblechorefval ] -row 1 -column 4 -sticky w
    set QWIKMD::advGui(analyze,advance,echotime) $frame.header.optframe.lblechorefval

    QWIKMD::balloon $frame.header.optframe.lblechorefval [QWIKMD::tempQTempTimeBL]

    grid [ttk::label $frame.header.optframe.lblfitting -text "Curve fitting equation = "] -row 2 -column 0 -sticky w
    grid [ttk::entry $frame.header.optframe.fittingentry -state normal -width 16 ] -row 2 -column 1 -sticky w
    $frame.header.optframe.fittingentry delete 0 end
    $frame.header.optframe.fittingentry insert end "y = exp(-x/a0)"
    $frame.header.optframe.fittingentry configure -state readonly

    QWIKMD::balloon $frame.header.optframe.fittingentry [QWIKMD::tempQTempEqBL]

    grid [ttk::button $frame.header.optframe.lblFEcho -text "Find Echo" -command QWIKMD::QFindEcho -padding "2 0 2 0"] -row 2 -column 4 -sticky e -padx 2 -pady 2
}

# proc QWIKMD::StartQTempstep {tbl row col text} {
#     set from 1
#     set to 500000
#     set w [$tbl editwinpath]
#     $w configure -from $from -to $to -increment 1
# }
##########################################################################
## Window to be inserted in the tablelist of temperature quench analysis
##########################################################################
proc QWIKMD::ProcSelect {tbl row col w} {
    grid [ttk::frame $w] -sticky news
    ttk::style configure selec.TCheckbutton -background white
    grid [ttk::checkbutton $w.r -style selec.TCheckbutton] -row 0 -column 0
    $w.r invoke
    $w.r state !selected
    return $w.r
}
#########################################################################
## Window to be inserted in the tablelist of temperature quench analysis
## and load trajectories
#########################################################################
proc QWIKMD::StartSelect {tbl row col w} {
    grid [ttk::frame $w] -sticky news
    ttk::style configure selec.TCheckbutton -background white
    grid [ttk::radiobutton $w.r -variable QWIKMD::curframe -value $row -style selec.TCheckbutton] -row 0 -column 0
    $w.r invoke
    $w.r state !selected
    return $w.r
}
###########################################################
## Check atom selection strings from entries or tablelists 
###########################################################
proc QWIKMD::checkSelection {w style} {
    set returnval 1
    set text [$w get]
    set sel ""
    set table $QWIKMD::selresTable 
    if {$text == "Type Selection"} {
        $w delete 0 end
        ttk::style configure $style -foreground black
        # ttk::style configure AtomSel.TEntry -foreground black
        if {$style == "AtomSel.TEntry"} {
            #$QWIKMD::selResGui.f1.frameOPT.manipul.buttFrame.butApply configure -state disabled
            $table selection clear 0 end
            QWIKMD::SelResClearSelection
        }
        return 0
    } elseif {$text == ""} {
        set returnval 0
    } else {
        set aux [catch {atomselect $QWIKMD::topMol $text} sel]
        if {$aux == 1} {
            tk_messageBox -message "Atom selection invalid." -icon error -type ok
            set returnval 0
        } else {
            if {[llength [$sel get resid]] == 0} {
                tk_messageBox -message "0 atoms selected. Please choose one or more atoms" -icon warning -type ok
                set returnval 0
            }
        }
        if {[regexp "QM Region Selection" [wm title $QWIKMD::selResGui]] && $returnval == 1} {
            ## define beta column of QM regions
            set qmID $QWIKMD::advGui(pntchrgopt,qmID)
            set text "same residue as ($text)"
            set selall [atomselect $QWIKMD::topMol "all"]
            $selall set beta 0
            $selall set occupancy 0
            $selall delete
            QWIKMD::getQMMM $QWIKMD::advGui(pntchrgopt,qmID) $text
            set text "all and beta == $qmID"
        }
    }
    if {$returnval == 0} {
        QWIKMD::SelResClearSelection
        $w delete 0 end
        $w insert end "Type Selection"
        ttk::style configure $style -foreground $QWIKMD::tempEntry
        return $returnval
    } else {
        ttk::style configure $style -foreground black
    }

    if {$style == "AtomSel.TEntry"} {
        #$QWIKMD::selResGui.f1.frameOPT.manipul.buttFrame.butApply configure -state normal
        if {[$w get] != "Type Selection" && $returnval == 1} {
            set QWIKMD::selResidSelIndex [list]
            foreach resid [$sel get resid] chain [$sel get chain] {
                if {[lsearch $QWIKMD::selResidSelIndex ${resid}_$chain] == -1} {
                    lappend QWIKMD::selResidSelIndex ${resid}_$chain
                }
            }
            $table selection clear 0 end
            QWIKMD::selResidForSelection [wm title $QWIKMD::selResGui] $QWIKMD::selResidSelIndex
        }
    }
    if {$sel != "" && $returnval == 0} {
        $sel delete
    }
    return $returnval
}
###########################################################
## Add notebook to accommodate plots 
###########################################################
proc QWIKMD::addplot {frame tadbtitle title xlab ylab} {
    set tabid [$QWIKMD::topGui.nbinput index current]
    set frameaux ""
    set framesection ""
    if {$tabid == 2} {
        set frameaux $QWIKMD::advGui(analyze,basic,ntb).$frame
        set framesection $QWIKMD::advGui(analyze,basic,ntb)
    } else {
        set frameaux $QWIKMD::advGui(analyze,advance,ntb).$frame
         set framesection $QWIKMD::advGui(analyze,advance,ntb)
    }

    set plotsection [file root [file root [file root $framesection]]]
    set arrow [lindex [${plotsection}.prt cget -text] 0]
    if {$arrow == $QWIKMD::rightPoint} {
        QWIKMD::hideFrame ${plotsection}.prt $plotsection "Plots"
    }
    if {[winfo exists $frameaux] != 1} {
        ttk::frame $frameaux
        grid columnconfigure $frameaux 0 -weight 1
        grid rowconfigure $frameaux 0 -weight 1
        set tabid [$QWIKMD::topGui.nbinput index current]
        if {$tabid == 2} {
            set level basic
        } else {
            set level advance
        }
        $QWIKMD::advGui(analyze,$level,ntb) add $frameaux -text $tadbtitle -sticky news

        grid [ttk::frame $frameaux.eplot] -row 0 -column 0 -sticky news
        grid columnconfigure $frameaux.eplot 0 -weight 1
        grid rowconfigure $frameaux.eplot 0 -weight 1

    }

    set plot [multiplot embed $frameaux.eplot -xsize 600 -ysize 400 -title $title -xlabel $xlab -ylabel $ylab -lines -linewidth 2 -marker point -radius 2 -autoscale  ]
    set plotwindow [$plot getpath]

    ## Add more menus to clear and close plots not included by
    ## default in the multiplot windows.
    menubutton $plotwindow.menubar.clear -text "Clear" \
    -underline 0 -menu $plotwindow.menubar.clear.menu
        
    $plotwindow.menubar.clear config -width 5

    menu $plotwindow.menubar.clear.menu -tearoff 0

    $plotwindow.menubar.clear.menu add command -label "Clear Plot"


    menubutton $plotwindow.menubar.close -text Close -underline 0 -menu $plotwindow.menubar.close.menu

    menu $plotwindow.menubar.close.menu -tearoff 0
    $plotwindow.menubar.close.menu add command -label "Close Plot"
    

    $plotwindow.menubar.close config -width 5


    pack $plotwindow.menubar.clear -side left
    pack $plotwindow.menubar.close -side left
    grid $plotwindow -row 0 -column 0 -sticky nwes
        
    return "$plot $plotwindow.menubar.clear.menu $plotwindow.menubar.close.menu"
}

proc QWIKMD::Select {tbl row col w} {
    grid [ttk::frame $w] -sticky news
    
    ttk::style configure select.TRadiobutton -background white
    grid [ttk::radiobutton $w.r -value [$tbl cellcget $row,[expr $col +1] -text] -style select.TRadiobutton -variable QWIKMD::radiobtt] -row 0 -column 0
    return $w.r
}

# proc QWIKMD::StartQTempstep {tbl row col text} {
#     return $text
# }

# proc QWIKMD::EndQTempstep {tbl row col text} {
#     return $text
# }
################################################################
## Generate a generic table to be used to select protocols
## load trajectories, temperature quench and restart simulation
################################################################
proc QWIKMD::addSelectTable {frame number} {
    set fro2 $frame
    option add *Tablelist.activeStyle       frame
    
    option add *Tablelist.movableColumns    no
    #option add *Tablelist.labelCommand      tablelist::sortByColumn


        tablelist::tablelist $fro2.tb
        $fro2.tb configure -columns {0 "Select" center 0 "Name" center}
        if {$number > 2} {
            $fro2.tb configure -columns {0 "Select" center 0 "Name" center 0 "tau" center}
        }       
        $fro2.tb configure -yscrollcommand [list $fro2.scr1 set] -xscrollcommand [list $fro2.scr2 set] \
                -showseparators 0 -labelrelief groove  -labelbd 1 -selectforeground black\
                -foreground black -background white -state normal -selectmode extended -height 5 -stretch all -stripebackgroun white -exportselection true\
                

    $fro2.tb columnconfigure 0 -selectbackground cyan
    $fro2.tb columnconfigure 1 -selectbackground cyan

    $fro2.tb columnconfigure 0 -sortmode integer -name Select
    $fro2.tb columnconfigure 1 -sortmode dictionary -name Name

    $fro2.tb columnconfigure 0 -width 0 -maxwidth 0
    $fro2.tb columnconfigure 1 -width 0 -maxwidth 0

    grid $fro2.tb -row 0 -column 0 -sticky news


    if {$number > 2} {
        $fro2.tb columnconfigure 2 -selectbackground cyan
        $fro2.tb columnconfigure 2 -sortmode dictionary -name tau
        $fro2.tb columnconfigure 2 -width 0 -maxwidth 0
    }   

    ##Scrool_BAr V
    scrollbar $fro2.scr1 -orient vertical -command [list $fro2.tb  yview]
     grid $fro2.scr1 -row 0 -column 1  -sticky ens

    ## Scrool_Bar H
    scrollbar $fro2.scr2 -orient horizontal -command [list $fro2.tb xview]
    
    grid $fro2.scr2 -row 1 -column 0 -sticky swe

    bind [$fro2.tb labeltag] <Any-Enter> {
        set col [tablelist::getTablelistColumn %W]
        set help 0
        switch $col {
            0 {
                set help [QWIKMD::selectTbSelectBL]
            }
            1 {
                set help [QWIKMD::selectTbNameBL]
            }
            2 {
                set help [QWIKMD::selectTbTauBL]
            }
            default {
                set help $col
            }
        }
        after 1000 [list QWIKMD::balloon:show %W $help]
    }
    
    bind [$fro2.tb labeltag] <Any-Leave> "destroy %W.balloon"
    return $fro2.tb

}
##############################################
## Build frame to accommodate plot notebooks
##############################################
proc QWIKMD::plotframe {frame level} {
    grid [ttk::frame $frame.header ] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header 0 -weight 1
    grid [ttk::label $frame.header.prt -text "$QWIKMD::rightPoint Plots"] -row 0 -column 0 -sticky ew -pady 1

    bind $frame.header.prt <Button-1> {
        QWIKMD::hideFrame %W [lindex [grid info %W] 1] "Plots"
    }

    grid [ttk::frame $frame.header.fcolapse ] -row 1 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frame.header.fcolapse 0 -weight 1

    grid [ttk::frame $frame.header.fcolapse.sep ] -row 0 -column 0 -sticky ew
    grid columnconfigure $frame.header.fcolapse.sep 0 -weight 1
    grid [ttk::separator $frame.header.fcolapse.spt -orient horizontal] -row 0 -column 0 -sticky ew -pady 0

    grid [ttk::frame $frame.header.fcolapse.fntb] -row 1 -column 0 -sticky news -padx 0 -pady 2
    grid columnconfigure $frame.header.fcolapse.sep 0 -weight 1

    grid [ttk::notebook $frame.header.fcolapse.fntb.ntb  -padding "0 0 0 0"] -row 0 -column 0 -sticky news -padx 0
    set QWIKMD::advGui(analyze,$level,ntb) $frame.header.fcolapse.fntb.ntb  
    grid forget $frame.header.fcolapse
    lappend QWIKMD::notebooks $frame.header.fcolapse.fntb.ntb
    
}

proc QWIKMD::killIMD {} {
    catch {imd kill}
    trace vdelete ::vmd_timestep($QWIKMD::topMol) w ::QWIKMD::updateMD 
}

proc QWIKMD::Finish {} {
    QWIKMD::killIMD
    if {$QWIKMD::state != [llength $QWIKMD::confFile]} {
        QWIKMD::updateMD
    } 
    set inputname [lindex $QWIKMD::confFile [expr $QWIKMD::state -1]]
    set fil [open $inputname.check w+]
    
    set done 1
    if {[file exists $inputname.restart.coor] != 1 || [file exists $inputname.restart.vel] != 1  || [file exists $inputname.restart.xsc] != 1  } {
        if {$QWIKMD::run == "SMD"} {
            if {[file exists $inputname.coor] != 1 } {
                set done 0
            } else {
                set done 1
            }
            
        } else {
            set done 0
        }
    } else {
        set done 1
    }

    ############################################################
    ## Save the last x axis value of the plots for simulation 
    ## restart purpose and in case of inputfile load
    ############################################################

    if {$done == 1} {
        puts $fil "DONE"
        if {[llength $QWIKMD::rmsd] > 0} {
            set QWIKMD::lastrmsd [expr [llength $QWIKMD::rmsd] -1]
        }

        if {[llength $QWIKMD::hbonds] > 0} {
            set QWIKMD::lasthbond [expr [llength $QWIKMD::hbonds] -1]
        }

        if {[llength $QWIKMD::smdvalsavg] > 0} {
            set QWIKMD::lastsmd [expr [llength $QWIKMD::smdvalsavg] -1]
        }

        if {[llength $QWIKMD::enetotval] > 0} {
            set QWIKMD::lastenetot [expr [llength $QWIKMD::enetotval] -1]
        }

        if {[llength $QWIKMD::enekinval] > 0} {
            set QWIKMD::lastenekin [expr [llength $QWIKMD::enekinval] -1]
        }

        if {[llength $QWIKMD::enepotval] > 0} {
            set QWIKMD::lastenepot [expr [llength $QWIKMD::enepotval] -1]
        }

        if {[llength $QWIKMD::enebondval] > 0} {
            set QWIKMD::lastenebond [expr [llength $QWIKMD::enebondval] -1]
        }

        if {[llength $QWIKMD::eneangleval] > 0} {
            set QWIKMD::lasteneangle [expr [llength $QWIKMD::eneangleval] -1]
        }

        if {[llength $QWIKMD::enedihedralval] > 0} {
            set QWIKMD::lastenedihedral [expr [llength $QWIKMD::enedihedralval] -1]
        }

        if {[llength $QWIKMD::enevdwval] > 0} {
            set QWIKMD::lastenevdw [expr [llength $QWIKMD::enevdwval] -1]
        }

        if {[llength $QWIKMD::tempval] > 0} {
            set QWIKMD::lasttemp [expr [llength $QWIKMD::tempval] -1]
        }
        if {[llength $QWIKMD::pressval] > 0} {
            set QWIKMD::lastpress [expr [llength $QWIKMD::pressvalavg] -1]
        }

        if {[llength $QWIKMD::volval] > 0} {
            set QWIKMD::lastvol [expr [llength $QWIKMD::volvalavg] -1]
        }
        
    } else {
        puts $fil "One or more files filed to be written"
        
        tk_messageBox -message "One or more files failed to be written. The new simulation ready to run is \
        [lindex $QWIKMD::confFile [expr $QWIKMD::state -1]]" -title "Running Simulation" -icon info -type ok -parent $QWIKMD::topGui
        
        ############################################################
        ## Delete values from the "failed" simulation
        ############################################################

        if {[llength $QWIKMD::rmsd] > 0} {
            set QWIKMD::rmsd [lrange $QWIKMD::rmsd 0 $QWIKMD::lastrmsd]
            set QWIKMD::timeXrmsd [lrange $QWIKMD::timeXrmsd 0 $QWIKMD::lastrmsd]
        }
        if {[llength $QWIKMD::hbonds] > 0} {
            set QWIKMD::hbonds [lrange $QWIKMD::hbonds 0 $QWIKMD::lasthbond]
            set QWIKMD::timeXhbonds [lrange $QWIKMD::timeXhbonds 0 $QWIKMD::lasthbond]
            
        }

        if {[llength $QWIKMD::smdvalsavg] > 0} {
            set QWIKMD::smdvalsavg [lrange $QWIKMD::smdvalsavg 0 $QWIKMD::lastsmd]
            set QWIKMD::timeXsmd [lrange $QWIKMD::timeXsmd 0 $QWIKMD::lastsmd]
        }

        if {[llength $QWIKMD::enetotval] > 0} {
            set QWIKMD::enetotval [lrange $QWIKMD::enetotval 0 $QWIKMD::lastenetot]
            set QWIKMD::enetotpos [lrange $QWIKMD::enetotpos 0 $QWIKMD::lastenetot]
        }

        if {[llength $QWIKMD::enekinval] > 0} {
            set QWIKMD::enekinval [lrange $QWIKMD::enekinval 0 $QWIKMD::lastenekin]
            set QWIKMD::enekinpos [lrange $QWIKMD::enekinpos 0 $QWIKMD::lastenekin]
        }

        if {[llength $QWIKMD::enepotval] > 0} {
            set QWIKMD::enepotval [lrange $QWIKMD::enepotval 0 $QWIKMD::lastenepot]
            set QWIKMD::enepotpos [lrange $QWIKMD::enepotpos 0 $QWIKMD::lastenepot]
        }

        if {[llength $QWIKMD::enebondval] > 0} {
            set QWIKMD::enebondval [lrange $QWIKMD::enebondval 0 $QWIKMD::lastenebond]
            set QWIKMD::enebondpos [lrange $QWIKMD::enebondpos 0 $QWIKMD::lastenebond]
        }

        if {[llength $QWIKMD::eneangleval] > 0} {
            set QWIKMD::eneangleval [lrange $QWIKMD::eneangleval 0 $QWIKMD::lasteneangle]
            set QWIKMD::eneanglepos [lrange $QWIKMD::eneanglepos 0 $QWIKMD::lasteneangle]
        }

        if {[llength $QWIKMD::enedihedralval] > 0} {
            set QWIKMD::enedihedralval [lrange $QWIKMD::enedihedralval 0 $QWIKMD::lastenedihedral]
            set QWIKMD::enedihedralpos [lrange $QWIKMD::enedihedralpos 0 $QWIKMD::lastenedihedral]
        }

        if {[llength $QWIKMD::enevdwval] > 0} {
            set QWIKMD::enevdwval [lrange $QWIKMD::enevdwval 0 $QWIKMD::lastenevdw]
            set QWIKMD::enevdwpos [lrange $QWIKMD::enevdwpos 0 $QWIKMD::lastenevdw]
        }

        if {[llength $QWIKMD::tempval] > 0} {
            set QWIKMD::tempval [lrange $QWIKMD::tempval 0 $QWIKMD::lasttemp]
            set QWIKMD::temppos [lrange $QWIKMD::temppos 0 $QWIKMD::lasttemp]
        }
        if {[llength $QWIKMD::pressval] > 0} {
            set QWIKMD::pressvalavg [lrange $QWIKMD::pressvalavg 0 $QWIKMD::lastpress]
            set QWIKMD::presspos [lrange $QWIKMD::presspos 0 $QWIKMD::lastpress]
        }

        if {[llength $QWIKMD::volval] > 0} {
            set QWIKMD::volvalavg [lrange $QWIKMD::volvalavg 0 $QWIKMD::lastvol]
            set QWIKMD::volpos [lrange $QWIKMD::volpos 0 $QWIKMD::lastvol]
        }
        file delete $inputname.check
        file delete $inputname.log
        if {$QWIKMD::state > 0} {
            incr QWIKMD::state -1
        }
        
    }
    set tabid [$QWIKMD::topGui.nbinput index current]
    set QWIKMD::prevcounterts $QWIKMD::counterts
     if {$QWIKMD::run == "SMD"} {
        set do 0
        if {$tabid == 0} {
            if {$QWIKMD::basicGui(prtcl,$QWIKMD::run,smd) == 1} {
                set do 1
            }
        } else {
            if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$QWIKMD::state,smd) == 1} {
                set do 1
            }
        }
        if {$do == 1} {
            set QWIKMD::prevcountertsmd $QWIKMD::countertssmd
        }  
    }

    QWIKMD::defaultIMDbtt $tabid normal
    [lindex $QWIKMD::preparebtt $tabid] configure -state normal
    # $QWIKMD::basicGui(preparebtt,$tabid) configure -state normal

    
    close $fil
    set QWIKMD::enecurrentpos 0
    set QWIKMD::smdcurrentpos 0
    set QWIKMD::condcurrentpos 0
    
    set QWIKMD::stop 1
}

proc QWIKMD::Detach {} {
    imd detach
    trace vdelete ::vmd_timestep($QWIKMD::topMol) w ::QWIKMD::updateMD 
}

proc QWIKMD::Pause {} {
    imd pause toggle
    set tabid [$QWIKMD::topGui.nbinput index current]
    set text "Pause"
    if {$QWIKMD::stop == 1} {
        set text "Resume"
        set QWIKMD::stop 0
    } else {
        set QWIKMD::stop 1
        set text "Pause" 
    }
    [lindex $QWIKMD::pausebtt $tabid] configure -text $text
}

############################################################
## Set the state of the IMD controllers in 
## the Simulation Control Frame
## tabid == tab index of the Main Notebook
## state == target state for the widgets (normal, disabled) 
############################################################
proc QWIKMD::defaultIMDbtt {tabid state} {
    [lindex $QWIKMD::runbtt $tabid] configure -state $state
    [lindex $QWIKMD::runbtt $tabid] configure -text "Start [QWIKMD::RunText]"
    [lindex $QWIKMD::detachbtt $tabid]  configure -state $state
    [lindex $QWIKMD::pausebtt $tabid]  configure -state $state
    [lindex $QWIKMD::pausebtt $tabid] configure -state $state -text "Pause"
    [lindex $QWIKMD::finishbtt $tabid]  configure -state $state
}
############################################################
## Residue Selection window builder. This window will become 
## a general structure manipulation window in the next versions
############################################################

proc QWIKMD::SelResidBuild {} {
    set tabid [$QWIKMD::topGui.nbinput index current]
    if {[winfo exists $QWIKMD::selResGui] != 1} {
        toplevel $QWIKMD::selResGui
    } else {
        wm deiconify $QWIKMD::selResGui
        raise $QWIKMD::selResGui
        return
    }   

    
    grid columnconfigure $QWIKMD::selResGui 0 -weight 2
    grid rowconfigure $QWIKMD::selResGui 0 -weight 2
    ## Title of the windows
    wm title $QWIKMD::selResGui "Structure Manipulation/Check" 

    wm protocol $QWIKMD::selResGui WM_DELETE_WINDOW {
        set QWIKMD::anchorpulling 0
        set QWIKMD::buttanchor 0
        if {$QWIKMD::topMol != ""} {
            QWIKMD::SelResClearSelection
            set QWIKMD::selResidSel "Type Selection"
        }
        wm withdraw $QWIKMD::selResGui
        QWIKMD::tableModeProc
        trace remove variable ::vmd_pick_event write QWIKMD::ResidueSelect
        mouse mode rotate
      }

    grid [ttk::frame $QWIKMD::selResGui.f1] -row 0 -column 0 -sticky nsew -padx 2 -pady 4
    grid columnconfigure $QWIKMD::selResGui.f1 0 -weight 0
    #grid columnconfigure $QWIKMD::selResGui.f1 1 -weight 1
    grid rowconfigure $QWIKMD::selResGui.f1 0 -weight 2
    #grid rowconfigure $QWIKMD::selResGui.f1 1 -weight 1

    grid [ttk::frame $QWIKMD::selResGui.f1.fcol1]  -row 0 -column 0 -sticky nsew -padx 2
    grid columnconfigure $QWIKMD::selResGui.f1.fcol1 0 -weight 1
    #grid columnconfigure $QWIKMD::selResGui.f1.fcol1 1 -weight 1
    grid rowconfigure $QWIKMD::selResGui.f1.fcol1 0 -weight 3 
    grid rowconfigure $QWIKMD::selResGui.f1.fcol1 1 -weight 1
    set selframe "$QWIKMD::selResGui.f1.fcol1"

    grid [ttk::frame $selframe.tableframe] -row 0 -column 0 -sticky nswe -padx 4

    ## Residues Table
    grid columnconfigure $selframe.tableframe 0 -weight 1
    grid rowconfigure $selframe.tableframe 0 -weight 1
    set fro2 $selframe.tableframe
    option add *Tablelist.activeStyle       frame
    
    option add *Tablelist.movableColumns    no
    option add *Tablelist.labelCommand      tablelist::sortByColumn


        tablelist::tablelist $fro2.tb \
        -columns { 0 "Res ID"    center
                0 "Res NAME"     center
                0 "Chain" center
                0 "Type" center
                } \
                -yscrollcommand [list $fro2.scr1 set] -xscrollcommand [list $fro2.scr2 set] \
                -showseparators 0 -labelrelief groove  -labelbd 1 -selectforeground black\
                -foreground black -background white -state normal -selectmode extended -stretch "all" -width 45 -stripebackgroun white -exportselection true\
                -editstartcommand QWIKMD::createResCombo -editendcommand QWIKMD::CallUpdateRes 

    $fro2.tb columnconfigure 0 -selectbackground cyan
    $fro2.tb columnconfigure 1 -selectbackground cyan
    $fro2.tb columnconfigure 2 -selectbackground cyan

    $fro2.tb columnconfigure 0 -sortmode integer -name ResID
    $fro2.tb columnconfigure 1 -sortmode dictionary -name ResNAME
    $fro2.tb columnconfigure 2 -sortmode dictionary -name Chain
    $fro2.tb columnconfigure 3 -sortmode dictionary -name Type
    
    $fro2.tb columnconfigure 0 -width 0 -maxwidth 0
    $fro2.tb columnconfigure 1 -width 0 -maxwidth 0 -editable true -editwindow ttk::combobox
    $fro2.tb columnconfigure 2 -width 0 -maxwidth 0
    $fro2.tb columnconfigure 3 -width 0 -maxwidth 0 -editable true -editwindow ttk::combobox


    grid $fro2.tb -row 0 -column 0 -sticky news
    $fro2.tb configure -height 35
    set QWIKMD::selresTable $fro2.tb

    ##Scrool_BAr V
    scrollbar $fro2.scr1 -orient vertical -command [list $fro2.tb  yview]
     grid $fro2.scr1 -row 0 -column 1  -sticky ens

    ## Scrool_Bar H
    scrollbar $fro2.scr2 -orient horizontal -command [list $fro2.tb xview]
    grid $fro2.scr2 -row 1 -column 0 -sticky swe

    bind [$fro2.tb labeltag] <Any-Enter> {
        set col [tablelist::getTablelistColumn %W]
        set help 0
        switch $col {
            0 {
                set help [QWIKMD::ResidselTabelResidBL]
            }
            1 {
                set help [QWIKMD::ResidselTabelResnameBL]
            }
            2 {
                set help [QWIKMD::ResidselTabelChainBL]
            }
            3 {
                set help [QWIKMD::ResidselTabelTypeBL]
            }
            default {
                set help $col
            }
        }
        after 1000 [list QWIKMD::balloon:show %W $help]
  
        
    }
    bind [$fro2.tb labeltag] <Any-Leave> "destroy %W.balloon"

    ## Patches text Frame

    grid [ttk::frame $selframe.patchframe] -row 1 -column 0 -sticky nswe -pady 2 -padx 2 
    grid [ttk::frame $selframe.patchframe.header] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $selframe.patchframe.header 0 -weight 1

    grid [ttk::label $selframe.patchframe.header.lbtitle -text "$QWIKMD::rightPoint Modifications (Patches) List"] -row 0 -column 0 -sticky nswe -pady 2 -padx 2  
    ttk::frame $selframe.patchframe.empty
    grid [ttk::labelframe $selframe.patchframe.header.fcolapse -labelwidget $selframe.patchframe.empty] -row 1 -column 0 -sticky ews -padx 2
    grid columnconfigure $selframe.patchframe.header.fcolapse 0 -weight 1

    bind $selframe.patchframe.header.lbtitle <Button-1> {
        QWIKMD::hideFrame %W [lindex [grid info %W] 1] "Modifications (Patches) List"
    }
    
    grid [ttk::label $selframe.patchframe.header.fcolapse.format -text "NAME CHAIN1 RES1 CHAIN2 RES2\nNAME CHAIN1 RES1 CHAIN2 RES2"] -row 1 -column 0 -sticky wns -padx 2 -pady 2
    grid [tk::text $selframe.patchframe.header.fcolapse.text -font tkconfixed -wrap none -bg white -height 4 -width 45 -font TkFixedFont -relief flat -foreground black \
    -yscrollcommand [list $selframe.patchframe.header.fcolapse.scr1 set] -xscrollcommand [list $selframe.patchframe.header.fcolapse.scr2 set]] -row 2 -column 0 -sticky wens
        ##Scrool_BAr V
    scrollbar $selframe.patchframe.header.fcolapse.scr1  -orient vertical -command [list $selframe.patchframe.header.fcolapse.text yview]
    grid $selframe.patchframe.header.fcolapse.scr1  -row 2 -column 1  -sticky ens

    ## Scrool_Bar H
    scrollbar $selframe.patchframe.header.fcolapse.scr2  -orient horizontal -command [list $selframe.patchframe.header.fcolapse.text xview]
    grid $selframe.patchframe.header.fcolapse.scr2 -row 3 -column 0 -sticky swe

    set QWIKMD::selresPatcheFrame $selframe.patchframe
    set QWIKMD::selresPatcheText $selframe.patchframe.header.fcolapse.text

    if {$tabid == 0} {
        grid forget $QWIKMD::selresPatcheFrame
    } else {
        grid configure $QWIKMD::selresPatcheFrame -row 1 -column 0 -sticky nswe -pady 2 -padx 2 
    }

    grid forget $selframe.patchframe.header.fcolapse 

    set selframe "$QWIKMD::selResGui.f1"
    grid [ttk::frame $selframe.frameOPT] -row 0 -column 1 -sticky nwe -padx 4
    grid columnconfigure $selframe.frameOPT 0 -weight 1

    QWIKMD::createInfoButton $selframe.frameOPT 0 0
    bind $selframe.frameOPT.info <Button-1> {
        set val [QWIKMD::selResiduesWindowinfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow selResiduesWindowinfo [lindex $val 0] [lindex $val 2]
    }
    
    ## Atom selection entry Frame

    grid [ttk::labelframe $selframe.frameOPT.atmsel -text "Atom Selection"] -row 1 -column 0 -sticky nwe -padx 4
    grid columnconfigure $selframe.frameOPT.atmsel 0 -weight 1 
    set QWIKMD::advGui(atmsel,frame) $selframe.frameOPT.atmsel

    ttk::style configure AtomSel.TEntry -foreground $QWIKMD::tempEntry
    grid [ttk::entry $selframe.frameOPT.atmsel.sel -style AtomSel.TEntry -exportselection false -textvariable QWIKMD::selResidSel -validate focus -validatecommand {
        # %V returns which event triggered the event.
        set text %V
        if {$text != "focusin" || [%W get] == "Type Selection"} {
            QWIKMD::checkSelection %W AtomSel.TEntry 
        } 
        return 1
    }] -row 0 -column 0 -sticky ew -padx 2

    bind $selframe.frameOPT.atmsel.sel <Return> {
        focus $QWIKMD::selResGui
    }
    set QWIKMD::advGui(atmsel,entry) $selframe.frameOPT.atmsel.sel
    set QWIKMD::selResidSel "Type Selection"
    if {$tabid == 0} {
        grid forget $QWIKMD::advGui(atmsel,frame) 
    }
    
    ## QM/MM option
    grid [ttk::frame $QWIKMD::selResGui.f1.frameOPT.qmreg] -row 2 -column 0 -sticky nwe -padx 4
    grid columnconfigure $QWIKMD::selResGui.f1.frameOPT.qmreg 0 -weight 1

    set qmframe $QWIKMD::selResGui.f1.frameOPT.qmreg
    set QWIKMD::advGui(qmregFrame) $qmframe

   
    # grid [ttk::frame $qmframe.pntcharges.pntchrgoptlbl] -row 1 -column 0 -sticky nw -padx 2
    # grid columnconfigure $qmframe.pntcharges.pntchrgoptlbl 0 -weight 1

    # grid [ttk::label $qmframe.pntcharges.pntchrgoptlbl.valatmnumb -text "0"] -row 1 -column 0 -sticky nw -padx 2
    # grid [ttk::label $qmframe.pntcharges.pntchrgoptlbl.lblatmnumb -text "atoms selected"] -row 1 -column 2 -sticky nw -padx 2
    # set QWIKMD::advGui(pntchrgopt,atmnumb) $qmframe.pntcharges.pntchrgoptlbl.valatmnumb

    grid [ttk::frame $qmframe.addsolv] -row 0 -column 0 -sticky nw -padx 2 -pady 2
    grid columnconfigure $qmframe.addsolv 0 -weight 1

    grid [ttk::label $qmframe.addsolv.lblsolv -text "Solvent within QM region"] -row 0 -column 0 -sticky nw -padx 2
    grid [ttk::entry $qmframe.addsolv.valsolv -textvariable QWIKMD::advGui(pntchrgopt,qmsolv) -exportselection false -width 4 -validate focus -validatecommand {
            # %V returns which event triggered the event.
            set text %V
            if {$text != "focusin" && [%W get] != ""} {
                QWIKMD::rowSelection
            } 
            return 1
    }] -row 0 -column 1 -sticky nsw -padx 2
    grid [ttk::label $qmframe.addsolv.lblsolvA -text "A"] -row 0 -column 2 -sticky nsw -padx 2
    set QWIKMD::advGui(pntchrgopt,qmsolv) 10
    set QWIKMD::advGui(pntchrgopt,qmsolv,entry) $qmframe.addsolv.valsolv

    bind $qmframe.addsolv.valsolv <Return> {
        focus $QWIKMD::selResGui
    }

    grid [ttk::frame $qmframe.lblnatoms] -row 1 -column 0 -sticky nw -padx 2 -pady 2
    grid columnconfigure $qmframe.lblnatoms 0 -weight 1

    grid [ttk::label $qmframe.lblnatoms.num -textvariable QWIKMD::advGui(qmregopt,atmnumb)] -row 0 -column 0 -sticky nw -padx 2
    grid [ttk::label $qmframe.lblnatoms.text -text "atoms selected"] -row 0 -column 1 -sticky nw -padx 2 
    set QWIKMD::advGui(qmregopt,atmnumb) 0

    grid [ttk::frame $qmframe.lblqmcharge] -row 2 -column 0 -sticky nw -padx 2 -pady 2
    grid columnconfigure $qmframe.lblqmcharge 0 -weight 1

    grid [ttk::label $qmframe.lblqmcharge.text -text "QM region total charge"] -row 0 -column 0 -sticky ew -padx 2
    grid [ttk::label $qmframe.lblqmcharge.val -textvariable QWIKMD::advGui(qmregopt,lblqmcharge)] -row 0 -column 1 -sticky ew -padx 2 
    set QWIKMD::advGui(qmregopt,lblqmcharge) 0

    grid [ttk::labelframe $qmframe.pntcharges -text "Point Charges"] -row 3 -column 0 -sticky nswe -padx 2 -pady 2
    grid columnconfigure $qmframe.pntcharges 0 -weight 1

    grid [ttk::frame $qmframe.pntcharges.pntchrgopt] -row 0 -column 0 -sticky nw -padx 2 -pady 2
    grid columnconfigure $qmframe.pntcharges.pntchrgopt 0 -weight 1

    grid [ttk::entry $qmframe.pntcharges.pntchrgopt.valpcDist -textvariable QWIKMD::advGui(pntchrgopt,pcDist) -width 4] -row 0 -column 0 -sticky nw -padx 2
    grid [ttk::label $qmframe.pntcharges.pntchrgopt.lblpcDist -text "A from the QM Region"] -row 0 -column 1 -sticky nw -padx 2
    set QWIKMD::advGui(pntchrgopt,pcDist) 10
    set QWIKMD::advGui(qmregopt,costumpntchrg) $qmframe.pntcharges
    grid forget $qmframe.pntcharges

    grid forget $qmframe
    
    


    ##### Table Mode options
    grid [ttk::frame $selframe.frameOPT.manipul] -row 3 -column 0 -sticky nwe -padx 0
    grid columnconfigure $selframe.frameOPT.manipul 0 -weight 1

    ttk::frame $selframe.frameOPT.manipul.empty
    grid [ttk::labelframe $selframe.frameOPT.manipul.tableMode -labelwidget $selframe.frameOPT.manipul.empty] -row 1 -column 0 -sticky nwe -padx 4
    grid columnconfigure $selframe.frameOPT.manipul.tableMode 0 -weight 1
    grid columnconfigure $selframe.frameOPT.manipul.tableMode 1 -weight 1
    set frametbmode $selframe.frameOPT.manipul.tableMode
    grid [ttk::radiobutton $frametbmode.mutate -text "Mutate" -variable QWIKMD::tablemode -value "mutate" -command {QWIKMD::tableModeProc}] -row 0 -column 0 -sticky nswe -padx 2
    grid [ttk::radiobutton $frametbmode.protstate -text "Prot. State" -variable QWIKMD::tablemode -value "prot" -command {QWIKMD::tableModeProc}] -row 0 -column 1 -sticky snwe -padx 2
    grid [ttk::radiobutton $frametbmode.add -text "Add" -variable QWIKMD::tablemode -value "add" -command {QWIKMD::tableModeProc}] -row 1 -column 0 -sticky nswe -padx 2
    grid [ttk::radiobutton $frametbmode.delete -text "Delete" -variable QWIKMD::tablemode -value "delete" -command {QWIKMD::tableModeProc}] -row 1 -column 1 -sticky nswe -padx 2
    grid [ttk::radiobutton $frametbmode.rename -text "Rename" -variable QWIKMD::tablemode -value "rename" -command {QWIKMD::tableModeProc}] -row 2 -column 1 -sticky nswe -padx 2
    grid [ttk::radiobutton $frametbmode.inspection -text "View" -variable QWIKMD::tablemode -value "inspection" -command {QWIKMD::tableModeProc}] -row 2 -column 0 -sticky nswe -padx 2
    grid [ttk::radiobutton $frametbmode.edit -text "Edit\nAtoms" -variable QWIKMD::tablemode -value "edit" -command {QWIKMD::tableModeProc}] -row 3 -column 0 -sticky nswe -padx 2
    grid [ttk::radiobutton $frametbmode.type -text "Type" -variable QWIKMD::tablemode -value "type" -command {QWIKMD::tableModeProc}] -row 3 -column 1 -sticky nswe -padx 2

    QWIKMD::balloon $frametbmode.mutate [QWIKMD::TableMutate]
    QWIKMD::balloon $frametbmode.protstate [QWIKMD::TableProtonate]
    QWIKMD::balloon $frametbmode.add [QWIKMD::TableAdd]
    QWIKMD::balloon $frametbmode.delete [QWIKMD::TableDelete]
    QWIKMD::balloon $frametbmode.rename [QWIKMD::TableRename]
    QWIKMD::balloon $frametbmode.inspection [QWIKMD::TableInspection]
    QWIKMD::balloon $frametbmode.type [QWIKMD::TableType]

    grid [ttk::frame $selframe.frameOPT.manipul.buttFrame] -row 2 -column 0 -sticky nwe -padx 4
    grid columnconfigure $selframe.frameOPT.manipul.buttFrame 0 -weight 1

    set framebutt $selframe.frameOPT.manipul.buttFrame

    ## Apply, Clear and Add Topo+Param Buttons

    grid [ttk::button $framebutt.butApply -text "Apply" -padding "4 2 4 2" -command {
        ## Ensure that the edit atoms window is not generated with the 
        ## generate topology for qm region options
        set QWIKMD::advGui(qmoptions,qmgentopo) 0
        ## Execute the operation dependent on the tablemode value
        QWIKMD::Apply
        } -state disabled] -row 0 -column 0 -sticky we -pady 4
    grid [ttk::button $framebutt.butClear -text "Clear Selection" -padding "4 2 4 2" -command { 
        QWIKMD::SelResClearSelection
        set QWIKMD::selResidSel "Type Selection"
        }] -row 1 -column 0 -sticky we -pady 4

    QWIKMD::balloon $framebutt.butApply [QWIKMD::TableApply]
    QWIKMD::balloon $framebutt.butClear [QWIKMD::TableClear]

    grid [ttk::button $framebutt.butAddTP -text "Add Topo+Param" -padding "4 2 4 2" -command {QWIKMD::AddTP} -state normal] -row 2 -column 0 -sticky we -pady 4

    ## Secondary Structure color labels 

    grid [ttk::frame $selframe.frameOPT.manipul.secStrc ] -row 3 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $selframe.frameOPT.manipul.secStrc 0 -weight 1

    set frameSecLabl $selframe.frameOPT.manipul.secStrc

    grid [ttk::frame $frameSecLabl.header] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $frameSecLabl.header 0 -weight 1

    grid [ttk::label $frameSecLabl.header.lbtitle -text "$QWIKMD::downPoint Sec. Struct colors"] -row 0 -column 0 -sticky nswe -pady 2 -padx 2  
    ttk::frame $frameSecLabl.empty
    grid [ttk::labelframe $frameSecLabl.header.fcolapse -labelwidget $selframe.frameOPT.manipul.secStrc.empty] -row 1 -column 0 -sticky ews -padx 2
    grid columnconfigure $frameSecLabl.header.fcolapse 0 -weight 1


    bind $frameSecLabl.header.lbtitle <Button-1> {
        QWIKMD::hideFrame %W [lindex [grid info %W] 1] "Sec. Struct colors"
    }
    
    set w [QWIKMD::drawColScale $frameSecLabl.header.fcolapse]
        
    QWIKMD::balloon $frameSecLabl.header.fcolapse [QWIKMD::TableSecLab]

    ## Residues table selection binding command 
    
    bind $fro2.tb <<TablelistSelect>>  {
        %W columnconfigure 0 -selectbackground cyan -selectforeground black
        %W columnconfigure 1 -selectbackground cyan -selectforeground black
        %W columnconfigure 2 -selectbackground cyan -selectforeground black
        # if {$QWIKMD::selResidSelRep != ""} {
        #     mol delrep [QWIKMD::getrepnum $QWIKMD::selResidSelRep] $QWIKMD::topMol
        # }
        set QWIKMD::selResidSel "Type Selection"
        set QWIKMD::selResidSelIndex [list]
        # set QWIKMD::selResidSelRep ""
        QWIKMD::rowSelection
    }

    ## Membrane builder controls frame

    grid [ttk::frame $selframe.frameOPT.manipul.membrane ] -row 4 -column 0 -sticky nwe -padx 2 -pady 2
    grid [ttk::frame $selframe.frameOPT.manipul.membrane.header] -row 0 -column 0 -sticky nswe -pady 2 -padx 2 
    grid columnconfigure $selframe.frameOPT.manipul.membrane.header 0 -weight 1

    grid [ttk::label $selframe.frameOPT.manipul.membrane.header.lbtitle -text "$QWIKMD::rightPoint Membrane"] -row 0 -column 0 -sticky nswe -pady 2 -padx 2  
    ttk::frame $selframe.frameOPT.manipul.membrane.empty
    grid [ttk::labelframe $selframe.frameOPT.manipul.membrane.header.fcolapse -labelwidget $selframe.frameOPT.manipul.membrane.empty] -row 1 -column 0 -sticky ews -padx 2
    grid columnconfigure $selframe.frameOPT.manipul.membrane.header.fcolapse 0 -weight 1

    bind $selframe.frameOPT.manipul.membrane.header.lbtitle <Button-1> {
        QWIKMD::hideFrame %W [lindex [grid info %W] 1] "Membrane"
    }
    grid forget $selframe.frameOPT.manipul.membrane.header.fcolapse

    set QWIKMD::advGui(membrane,frame) $selframe.frameOPT.manipul.membrane
    grid columnconfigure $selframe.frameOPT.manipul.membrane 0 -weight 1

    set frameMembrane $selframe.frameOPT.manipul.membrane.header.fcolapse

    grid [ttk::frame $frameMembrane.lipidopt]  -row 0 -column 0 -sticky news
    grid columnconfigure $frameMembrane.lipidopt 1 -weight 1
    grid [ttk::label $frameMembrane.lipidopt.lblipid -text "Lipid "] -row 0 -column 0 -sticky e -padx 2
    set values {POPC POPE} 
    grid [ttk::combobox $frameMembrane.lipidopt.combolipid -justify left -values $values -state readonly -textvariable QWIKMD::advGui(membrane,lipid) ] -row 0 -column 1 -sticky ew -padx 2

    bind $frameMembrane.lipidopt.combolipid <<ComboboxSelected>> {
        if {[info exists QWIKMD::advGui(membrane,center,x)]} {
            QWIKMD::updateMembraneBox [list $QWIKMD::advGui(membrane,center,x) $QWIKMD::advGui(membrane,center,y) $QWIKMD::advGui(membrane,center,z)]           
        }
        %W selection clear  
    }

    grid [ttk::frame $frameMembrane.size]  -row 1 -column 0 -sticky news -pady 2
    grid columnconfigure $frameMembrane.size 0 -weight 1

    grid [ttk::label $frameMembrane.size.x -text "x" ] -row 0 -column 0 -sticky w -padx 2
    grid [ttk::entry $frameMembrane.size.xentry -width 4 -textvariable QWIKMD::advGui(membrane,xsize) -validate focusout -validatecommand {
        if {[info exists QWIKMD::advGui(membrane,center,x)]} {
            QWIKMD::updateMembraneBox [list $QWIKMD::advGui(membrane,center,x) $QWIKMD::advGui(membrane,center,y) $QWIKMD::advGui(membrane,center,z)]           
        }
        return 0
    }] -row 0 -column 1 -sticky we -padx 2
    grid [ttk::label $frameMembrane.size.xA -text "A"] -row 0 -column 2 -sticky we -padx 2

    grid [ttk::label $frameMembrane.size.y -text "y"] -row 0 -column 3 -sticky w -padx 2
    grid [ttk::entry $frameMembrane.size.yentry -width 4 -textvariable QWIKMD::advGui(membrane,ysize) -validate focusout -validatecommand {
        if {[info exists QWIKMD::advGui(membrane,center,y)]} {
            QWIKMD::updateMembraneBox [list $QWIKMD::advGui(membrane,center,x) $QWIKMD::advGui(membrane,center,y) $QWIKMD::advGui(membrane,center,z)]
        }
        return 0
    }] -row 0 -column 4 -sticky ew 
    grid [ttk::label $frameMembrane.size.yA -text "A"] -row 0 -column 5 -sticky we -padx 2

    grid [ttk::button $frameMembrane.size.box -text "Box" -padding "1 0 1 0" -command {
        QWIKMD::AddMBBox
        QWIKMD::DrawBox
    }] -row 0 -column 6 -sticky w

    grid [ttk::frame $frameMembrane.move]  -row 2 -column 0 -sticky news -pady 2
    grid [ttk::radiobutton $frameMembrane.move.translate -text "Translate" -variable QWIKMD::advGui(membrane,efect) -value "translate"] -row 0 -column 0 -sticky w -padx 2
    grid [ttk::radiobutton $frameMembrane.move.rotate -text "Rotate" -variable QWIKMD::advGui(membrane,efect) -value "rotate"] -row 0 -column 1 -sticky w -padx 2

    grid [ttk::frame $frameMembrane.axis]  -row 3 -column 0 -sticky news -pady 2    
    grid columnconfigure $frameMembrane.axis 0 -weight 1

    grid [ttk::frame $frameMembrane.axis.axisopt] -row 0 -column 0 -sticky news
    grid columnconfigure $frameMembrane.axis.axisopt 0 -weight 1
    grid columnconfigure $frameMembrane.axis.axisopt 1 -weight 1
    grid columnconfigure $frameMembrane.axis.axisopt 2 -weight 1

    grid [ttk::radiobutton $frameMembrane.axis.axisopt.x -text "x" -variable QWIKMD::advGui(membrane,axis) -value "x"] -row 0 -column 0 -sticky w -padx 2
    grid [ttk::radiobutton $frameMembrane.axis.axisopt.y -text "y" -variable QWIKMD::advGui(membrane,axis) -value "y"] -row 0 -column 1 -sticky w -padx 2
    grid [ttk::radiobutton $frameMembrane.axis.axisopt.z -text "z" -variable QWIKMD::advGui(membrane,axis) -value "z"] -row 0 -column 2 -sticky w -padx 2

    grid [ttk::frame $frameMembrane.axis.axismulti] -row 4 -column 0 -sticky news
    grid columnconfigure $frameMembrane.axis.axismulti 0 -weight 1
    grid columnconfigure $frameMembrane.axis.axismulti 1 -weight 1
    grid columnconfigure $frameMembrane.axis.axismulti 2 -weight 1
    grid columnconfigure $frameMembrane.axis.axismulti 3 -weight 1

    grid [ttk::button $frameMembrane.axis.axismulti.minus2 -text "--" -padding "1 0 1 0" -width 2 -command {
        if {$QWIKMD::advGui(membrane,efect) == "translate"} {
            set QWIKMD::advGui(membrane,multi) 5
        } else {
            set QWIKMD::advGui(membrane,multi) 15
        }
        QWIKMD::incrMembrane "-"
        }] -row 0 -column 0 -sticky ew
    grid [ttk::button $frameMembrane.axis.axismulti.minus -text "-" -padding "1 0 1 0" -width 2 -command {
        set QWIKMD::advGui(membrane,multi) 1
        QWIKMD::incrMembrane "-"
        }] -row 0 -column 1 -sticky ew

    grid [ttk::button $frameMembrane.axis.axismulti.plus -text "+"  -padding "1 0 1 0" -width 2 -command {
        set QWIKMD::advGui(membrane,multi) 1
        QWIKMD::incrMembrane "+"
        }] -row 0 -column 2 -sticky ew
    grid [ttk::button $frameMembrane.axis.axismulti.plus2 -text "++"  -padding "1 0 1 0" -width 2 -command {
        if {$QWIKMD::advGui(membrane,efect) == "translate"} {
            set QWIKMD::advGui(membrane,multi) 5
        } else {
            set QWIKMD::advGui(membrane,multi) 15
        }
        QWIKMD::incrMembrane "+"
        }] -row 0 -column 3 -sticky ew

    grid [ttk::frame $frameMembrane.buttons]  -row 4 -column 0 -sticky we -pady 2
    grid columnconfigure $frameMembrane.buttons 0 -weight 1
    grid columnconfigure $frameMembrane.buttons 1 -weight 1

    grid [ttk::button $frameMembrane.buttons.generate -text "Generate" -padding "1 0 1 0" -command QWIKMD::GenerateMembrane] -row 0 -column 0 -sticky ew
    grid [ttk::button $frameMembrane.buttons.delete -text "Delete" -padding "1 0 1 0" -command {
        QWIKMD::deleteMembrane
    }] -row 0 -column 1 -sticky ew

    grid [ttk::button $frameMembrane.optimize -text "Optimize Size" -padding "1 0 1 0" -command {
        if {$QWIKMD::membraneFrame == ""} {
            tk_messageBox -message "To optimize membrane size, please generate the membrane first." -type ok -icon warning -parent $QWIKMD::selResGui
            return
        }
        QWIKMD::OptSize
    }] -row 5 -column 0 -sticky we

    set QWIKMD::advGui(membrane,lipid) POPC
    set QWIKMD::advGui(membrane,xsize) 30
    set QWIKMD::advGui(membrane,ysize) 30
    set QWIKMD::advGui(membrane,efect) "translate"
    set QWIKMD::advGui(membrane,axis) "x"
    set QWIKMD::advGui(membrane,multi) "1"

    if {$tabid == 0} {
        grid forget $QWIKMD::advGui(membrane,frame)

    }
    QWIKMD::tableModeProc

    ## Structure Check summary frame

    grid [ttk::labelframe $selframe.frameOPT.manipul.strctChck -text "Structure Check" -padding "0 0 0 0"] -row 5 -column 0 -sticky nwe -padx 2 -pady 2
    grid columnconfigure $selframe.frameOPT.manipul.strctChck 0 -weight 1

    set frameStrcuCheck $selframe.frameOPT.manipul.strctChck

    grid [ttk::frame $frameStrcuCheck.messages ] -row 0 -column 0 -sticky nwes -padx 2 -pady 2
    grid columnconfigure $frameStrcuCheck.messages 1 -weight 1
    grid columnconfigure $frameStrcuCheck.messages 0 -weight 0
    set row 0

    set messageframe $selframe.frameOPT.manipul.strctChck.messages

    grid [label $messageframe.topoerror -background green -width 2 -relief raised -height 1 ] -row $row -column 0 -sticky e -padx 0 -pady 0
    set QWIKMD::topocolor $messageframe.topoerror

    grid [ttk::label $messageframe.topoerrortxt] -row $row -column 1 -sticky w
    set  QWIKMD::topolabel $messageframe.topoerrortxt
    bind $messageframe.topoerrortxt <Button-1> {
        set val [QWIKMD::TopologiesInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow toporeport [lindex $val 0] [lindex $val 2]
    }

    incr row
    grid [label $messageframe.chirerror -background green -width 2 -relief raised -height 1] -row $row -column 0 -sticky e -padx 0 -pady 0 -pady 2
    set QWIKMD::chircolor $messageframe.chirerror

    grid [ttk::label $messageframe.chirerrortxt -padding "0 0 0 0"] -row $row -column 1 -sticky w
    set QWIKMD::chirlabel $messageframe.chirerrortxt


    bind $messageframe.chirerrortxt <Button-1> {
        set val [QWIKMD::ChiralityInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow chirerror [lindex $val 0] [lindex $val 2]
    }

    incr row
    grid [label $messageframe.cispeperror -background green -width 2 -relief raised -height 1] -row $row -column 0 -sticky e -padx 0 -pady 0 -pady 2
    set QWIKMD::cispcolor $messageframe.cispeperror

    grid [ttk::label $messageframe.cispeperrortxt -padding "0 0 0 0"] -row $row -column 1 -sticky w
    set QWIKMD::cisplabel $messageframe.cispeperrortxt


    bind $messageframe.cispeperrortxt <Button-1> {
        set val [QWIKMD::CispeptideInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow cisperror [lindex $val 0] [lindex $val 2]
    }

    incr row
    grid [label $messageframe.gapserror -background green -width 2 -relief raised -height 1] -row $row -column 0 -sticky e -padx 0 -pady 0 -pady 2
    set QWIKMD::gapscolor $messageframe.gapserror

    grid [ttk::label $messageframe.gapserrortxt -padding "0 0 0 0"] -row $row -column 1 -sticky w
    set QWIKMD::gapslabel $messageframe.gapserrortxt


    bind $messageframe.gapserrortxt <Button-1> {
        set val [QWIKMD::GapsInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow gapsreport [lindex $val 0] [lindex $val 2]
    }

    incr row
    grid [label $messageframe.torsionOut -background green -width 2 -relief raised -height 1] -row $row -column 0 -sticky e -padx 0 -pady 0
    set QWIKMD::torsionOutliearcolor $messageframe.torsionOut

    grid [ttk::label $messageframe.torsionOuttxt -padding "0 0 0 0"] -row $row -column 1 -sticky w
    set QWIKMD::torsionOutliearlabel $messageframe.torsionOuttxt


    bind $messageframe.torsionOuttxt <Button-1> {
        set val [QWIKMD::TorsionOutlierInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow torsionOut [lindex $val 0] [lindex $val 2]
    }

    incr row
    grid [label $messageframe.torsionMarginal -background green -width 2 -relief raised -height 1] -row $row -column 0 -sticky e -padx 0 -pady 0
    set QWIKMD::torsionMarginalcolor $messageframe.torsionMarginal

    grid [ttk::label $messageframe.torsionMarginaltxt -padding "0 0 0 0"] -row $row -column 1 -sticky w
    set QWIKMD::torsionMarginallabel $messageframe.torsionMarginaltxt


    bind $messageframe.torsionMarginaltxt <Button-1> {
        set val [QWIKMD::TorsionMarginalInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow torsionMarginal [lindex $val 0] [lindex $val 2]
    }

    grid [ttk::frame $frameStrcuCheck.buttons ] -row 1 -column 0 -sticky we -padx 2 -pady 2
    grid columnconfigure $frameStrcuCheck.buttons 0 -weight 1
    grid columnconfigure $frameStrcuCheck.buttons 1 -weight 1

    grid [ttk::button $frameStrcuCheck.buttons.ignore -command {
        set color white
        set labellist [list $QWIKMD::chircolor $QWIKMD::cispcolor $QWIKMD::gapscolor $QWIKMD::torsionMarginalcolor $QWIKMD::torsionOutliearcolor]
        foreach label $labellist {
            if {[$label cget -background] != "green"} {
                $label configure -background $color
            }
        }
        
        if {[lindex $QWIKMD::topoerror 0] != 0} {
            set QWIKMD::warnresid 1
            tk_messageBox -message "Missing Topologies cannot be ignored.\
            \nPlease refer to the \"Structure Manipulation/Check\" window to fix them" -title "Missing Topologies" -icon warning \
            -type ok -parent $QWIKMD::selResGui
        } else {
            if {[$QWIKMD::topocolor cget -background] != "green"} {
                $QWIKMD::topocolor configure -background $color
            }
            set QWIKMD::warnresid 0
        }
    } -padding "2 0 2 0" -text "Ignore"] -row 0 -column 0 -sticky we
    
    grid [ttk::button $frameStrcuCheck.buttons.check -command QWIKMD::callCheckStructure -padding "2 0 2 0" -text "Check"] -row 0 -column 1 -sticky we
}
#####################################################################################################
## Proc to call the command invoked from the "Check" (structure) button
#####################################################################################################
proc QWIKMD::callCheckStructure {} {
    QWIKMD::messageWindow "Checking Structure" "Checking structure with \
        the new molecule type definitions"
    # QWIKMD::reviewTopPar 0
    # QWIKMD::loadTopologies
    # QWIKMD::UpdateMolTypes $QWIKMD::tabprevmodf
    QWIKMD::checkStructur load button
    destroy $QWIKMD::messWinGui
}
#####################################################################################################
## Window to be used to display messages
#####################################################################################################
proc QWIKMD::messageWindow {title message} {
    toplevel $QWIKMD::messWinGui
    grid columnconfigure $QWIKMD::messWinGui 0 -weight 1
    grid rowconfigure $QWIKMD::messWinGui 0 -weight 1

    wm title $QWIKMD::messWinGui $title

    grid [ttk::frame $QWIKMD::messWinGui.f1] -row 0 -column 0 -sticky nsew -padx 2 -pady 4
    grid columnconfigure $QWIKMD::messWinGui.f1 0 -weight 0

    grid [ttk::label $QWIKMD::messWinGui.f1.text -text $message] -row 0 -column 0 -sticky nsew -padx 2 -pady 4
    ## extracted from http://wiki.tcl.tk/1254
    update
    wm resizable $QWIKMD::messWinGui 0 0
    set width [winfo reqwidth $QWIKMD::messWinGui]
    set height [winfo reqheight $QWIKMD::messWinGui]
    set x [expr { ( [winfo vrootwidth  $QWIKMD::messWinGui] - $width  ) / 2 }]
    set y [expr { ( [winfo vrootheight $QWIKMD::messWinGui] - $height ) / 2 }]

    wm geometry $QWIKMD::messWinGui ${width}x${height}+${x}+${y}
    update
}
#####################################################################################################
## Build trajectory load window - filetype == dcd
## or
## protocol to select starting step to restart a new simulation (QM/MM) - filetype == "restart.coor" 
#####################################################################################################
proc QWIKMD::LoadOptBuild {tabid filetype} {
    $QWIKMD::topGui.nbinput tab 0 -state disabled
    $QWIKMD::topGui.nbinput tab 1 -state disabled
    $QWIKMD::topGui.nbinput tab 2 -state disabled
    $QWIKMD::topGui.nbinput tab 3 -state disabled
    set loadoptWindow ".loadopt"

    if {[winfo exists $loadoptWindow] != 1} {
        toplevel $loadoptWindow
        wm protocol $loadoptWindow WM_DELETE_WINDOW {
            destroy ".loadopt"
        }
        
        wm minsize $loadoptWindow -1 -1
        #wm resizable $loadoptWindow 0 0

        grid columnconfigure $loadoptWindow 0 -weight 1
        grid rowconfigure $loadoptWindow 1 -weight 1
        ## Title of the windows
        if {${filetype} == "dcd"} {
            wm title $loadoptWindow  "Loading Trajectories"
        } else {
            wm title $loadoptWindow  "Select Starting Step"
        }
        # wm title $loadoptWindow  "Loading Trajectories"
        set x [expr round([winfo screenwidth .]/2.0)]
        set y [expr round([winfo screenheight .]/2.0)]
        wm geometry $loadoptWindow -$x-$y
        set row 0

        grid [ttk::frame $loadoptWindow.f0] -row $row -column 0 -sticky ew -padx 4 -pady 4
        incr row

        if {$tabid == 0} {
            set solvent $QWIKMD::basicGui(solvent,$QWIKMD::run,0)
        } else {
            set solvent $QWIKMD::advGui(solvent,$QWIKMD::run,0)
        }
        if {$solvent == "Explicit" && [string first "Windows" $::tcl_platform(os)] == -1 && ${filetype} == "dcd"} {
            grid [ttk::checkbutton $loadoptWindow.f0.checkWaters -text "Don't load water molecules?" -variable QWIKMD::loadremovewater] -row 0 -column 0 -sticky w -padx 2
            grid [ttk::checkbutton $loadoptWindow.f0.checkIons -text "Don't load solvent ion molecules?" -variable QWIKMD::loadremoveions] -row 1 -column 0 -sticky w -padx 2
            grid [ttk::checkbutton $loadoptWindow.f0.checkhydrogen -text "Don't load hydrogen atoms?" -variable QWIKMD::loadremovehydrogen] -row 2 -column 0 -sticky w -padx 2
        }
        set text "Select Trajectories"
        if {${filetype} != "dcd"} {
            set text "Select Restart"
        } 
        grid [ttk::labelframe $loadoptWindow.ftable -text $text] -row $row -column 0 -sticky nsew -padx 4 -pady 4
        incr row

        grid columnconfigure $loadoptWindow.ftable 0 -weight 1
        grid rowconfigure $loadoptWindow.ftable 0 -weight 1

        set table [QWIKMD::addSelectTable $loadoptWindow.ftable 2]

        set listprot [list]
        if {[catch {glob ${QWIKMD::outPath}/run/*.${filetype}} listprot] == 0} {
            set j 0
            $table insert end "{} {}"
            set text ""
            if {${filetype} == "dcd"} {
                set text "Initial Structure"
                $table cellconfigure end,0 -window QWIKMD::ProcSelect
            } else {
                set text "Current Frame"
                $table cellconfigure end,0 -window QWIKMD::StartSelect
            }
            $table cellconfigure end,1 -text $text
            [$table windowpath $j,0].r state selected
            incr j
            set QWIKMD::state 0
            for {set i 0} {$i < [llength $QWIKMD::prevconfFile]} {incr i} {
                if {[lsearch $listprot "*/[lindex $QWIKMD::prevconfFile $i].${filetype}"] > -1} {
                    $table insert end "{} {}"
                    if {${filetype} == "dcd"} {
                        $table cellconfigure end,0 -window QWIKMD::ProcSelect
                    } else {
                        $table cellconfigure end,0 -window QWIKMD::StartSelect
                    }
                    $table cellconfigure end,1 -text [lindex $QWIKMD::prevconfFile $i]
                    [$table windowpath $j,0].r state !selected
                    incr QWIKMD::state
                    incr j
                }
            }
            if {${filetype} != "dcd"} {
                set QWIKMD::curframe 0
                if {$QWIKMD::load == 1} {
                    set psf ""
                    if {[llength $psf] > 1 && [catch {glob ${QWIKMD::outPath}/run/*.psf} psf] == 0} {
                        set QWIKMD::curframe 1
                        [$table windowpath 0,0].r configure -state disabled 
                    } 
                }
            }
            
        }

        if {${filetype} == "dcd"} {
            grid [ttk::frame $loadoptWindow.fstride] -row $row -column 0 -sticky ew -padx 4 -pady 4
            incr row
            grid columnconfigure $loadoptWindow.fstride 1 -weight 1
            grid rowconfigure $loadoptWindow.fstride 0 -weight 1

            grid [ttk::label $loadoptWindow.fstride.lstride -text "Loading Trajectory Frame Step (Stride)"] -row 0 -column 0 -sticky w -padx 2
            grid [ttk::entry $loadoptWindow.fstride.entryStride -textvariable QWIKMD::loadstride -width 6] -row 0 -column 1 -sticky ew
            
            set QWIKMD::strdentry $loadoptWindow.fstride.entryStride

            grid [ttk::frame $loadoptWindow.flststep] -row $row -column 0 -sticky ew -padx 2 -pady 2
            incr row

            grid columnconfigure $loadoptWindow.flststep 0 -weight 1
            grid rowconfigure $loadoptWindow.flststep 0 -weight 1

            grid [ttk::checkbutton $loadoptWindow.flststep.laststep -text "Load Simulations Last Step" -variable QWIKMD::loadlaststep -command {
                if {$QWIKMD::loadlaststep == 1} {
                    set QWIKMD::loadstride 1
                    set QWIKMD::loadremovewater 0
                    set QWIKMD::loadremoveions 0
                    set QWIKMD::loadremovehydrogen 0
                    $QWIKMD::strdentry configure -state disabled
                } else {
                    $QWIKMD::strdentry configure -state normal
                }
            }] -row 0 -column 0 -sticky e -padx 2 

        } 
        set QWIKMD::loadlaststep 0
        grid [ttk::frame $loadoptWindow.fbutton] -row $row -column 0 -sticky e -padx 4 -pady 4
        incr row

        if {${filetype} == "dcd"} {
            grid [ttk::button $loadoptWindow.fbutton.okBut -text "Ok" -padding "1 0 1 0" -width 15 -command {
                
                set table ".loadopt.ftable.tb"
                set QWIKMD::loadprotlist [list]
                set i 0
                foreach prtcl [$table getcolumns 1] {
                    set chcbt [$table windowpath $i,0].r
                    set state [$chcbt state !selected]
                    if { $state == "selected" && $i == 0} {
                        set QWIKMD::loadinitialstruct 1
                    } elseif {$state == "selected"} {
                        lappend QWIKMD::loadprotlist $prtcl
                    }
                    incr i
                }
                if {[llength $QWIKMD::loadprotlist] == 0 && $QWIKMD::loadinitialstruct == 0} {
                    if {${filetype} == "dcd"} {
                        tk_messageBox -message "Please select at least one the trajectories or the Initial Structure to be loaded in VMD." \
                        -icon warning -type ok -title "No Trajectory Selected" -parent ".loadopt"
                    } 
                    # elseif {$QWIKMD::curframe == 0} {
                    #     tk_messageBox -message "Please select at least one of the starting points or the Current Frame as initial state." -icon warning -type ok -title "No Starting Point Selected"
                    # }
                } else {
                    destroy ".loadopt"
                }
                
            } ] -row 0 -column 0 -sticky ns
        } else {
            grid [ttk::button $loadoptWindow.fbutton.okBut -text "Ok" -padding "1 0 1 0" -width 15 -command {
                
                set table ".loadopt.ftable.tb"
                set QWIKMD::loadprotlist [list]
              
                set prtcl [$table getcolumns 1] 
                set QWIKMD::loadprotlist [lindex $prtcl $QWIKMD::curframe]
                 destroy ".loadopt"
            } ] -row 0 -column 0 -sticky ns
        }
        grid [ttk::button $loadoptWindow.fbutton.cancel -text "Cancel" -padding "1 0 1 0" -width 15 -command {
            set QWIKMD::loadprotlist "Cancel"
            destroy ".loadopt"
            } ] -row 0 -column 1 -sticky ns
        #raise $procWindow
    } else {
        wm deiconify $loadoptWindow
    }
    tkwait window $loadoptWindow
    $QWIKMD::topGui.nbinput tab 0 -state normal
    $QWIKMD::topGui.nbinput tab 1 -state normal
    $QWIKMD::topGui.nbinput tab 2 -state normal
    $QWIKMD::topGui.nbinput tab 3 -state normal
}


############################################################
## Lock and unlock Structure Manipulation/Check Window in the case 
## of Atom selection functions (e.g. Selecting anchoring/pulling residues)
## opt 0 === lock
## opt 1 === unlock
############################################################
proc QWIKMD::lockSelResid {opt} {
    set frame "$QWIKMD::selResGui.f1.frameOPT.manipul"
    if {$opt == 0} {
        if {[winfo exists $frame.tableMode]} {
            grid forget $frame.tableMode
        }
        if {[winfo exists $frame.buttFrame.butAddTP]} {
            grid forget $frame.buttFrame.butAddTP
        }
        if {[winfo exists $QWIKMD::advGui(membrane,frame)]} {
            grid forget $QWIKMD::advGui(membrane,frame)
        }
        if {[winfo exists $QWIKMD::selresPatcheFrame]} {
            grid forget $QWIKMD::selresPatcheFrame
        }
        if {[winfo exists $frame.strctChck]} {
            grid forget $frame.strctChck
        }
        if {[winfo exists $QWIKMD::advGui(atmsel,frame)] == 1} {
            if {($QWIKMD::anchorpulling == 1 && $QWIKMD::run == "SMD") || [$QWIKMD::topGui.nbinput index current] == 0 || [regexp "Center of Mass Region Selection" [wm title $QWIKMD::selResGui] ]} {
                grid forget $QWIKMD::advGui(atmsel,frame)
            } elseif {[$QWIKMD::topGui.nbinput index current] == 1} {
                grid conf $QWIKMD::advGui(atmsel,frame) -row 1 -column 0 -sticky nwe -padx 4
                set tabid [$QWIKMD::topGui.nbinput index current]
                if {[lindex [lindex $QWIKMD::selnotbooks 0] 1] == $tabid && [lindex [lindex $QWIKMD::selnotbooks 1] 1] == [$QWIKMD::topGui.nbinput.f[expr $tabid +1].nb index current]} {
                    if {[regexp "QM Region Selection" [wm title $QWIKMD::selResGui]]} {
                        $QWIKMD::advGui(atmsel,entry) configure -state readonly
                    }
                    $QWIKMD::advGui(pntchrgopt,qmsolv,entry) configure -state readonly
                } else {
                    if {[regexp "QM Region Selection" [wm title $QWIKMD::selResGui]]} {
                        $QWIKMD::advGui(atmsel,entry) configure -state normal
                    } 
                    $QWIKMD::advGui(pntchrgopt,qmsolv,entry) configure -state normal 
                }
            }
        } 
        if {[regexp "QM Region Selection" [wm title $QWIKMD::selResGui]] == 1} {
            grid conf $QWIKMD::advGui(qmregFrame) -row 2 -column 0 -sticky nwe -padx 4
            if {$QWIKMD::advGui(qmoptions,cmptcharge) == "On"} {
                grid conf $QWIKMD::advGui(qmregopt,costumpntchrg) -row 3 -column 0 -sticky nwe -padx 2 -pady 2
            } else {
                grid forget $QWIKMD::advGui(qmregopt,costumpntchrg)
            }
        } else {
            grid forget $QWIKMD::advGui(qmregFrame)
            grid forget $QWIKMD::advGui(qmregopt,costumpntchrg)
        }
        
    } elseif {$opt == 1} {
        $frame.tableMode.mutate configure -state normal
        $frame.tableMode.protstate configure -state normal
        $frame.tableMode.add configure -state normal
        $frame.tableMode.delete configure -state normal
        $frame.tableMode.rename configure -state normal
        $frame.tableMode.type configure -state normal
        $frame.tableMode.edit configure -state normal
        $frame.buttFrame.butAddTP configure -state normal
        if {[$QWIKMD::topGui.nbinput index current] == 1} {
            grid conf $QWIKMD::advGui(atmsel,frame) -row 1 -column 0 -sticky nwe -padx 4
            $QWIKMD::advGui(atmsel,entry) configure -state normal
            if {$QWIKMD::prepared == 0 && $QWIKMD::load == 0 && [wm title $QWIKMD::selResGui] == "Structure Manipulation/Check"} {
                grid conf $QWIKMD::advGui(membrane,frame) -row 4 -column 0 -sticky nwe -padx 2 -pady 2
                grid conf $QWIKMD::selresPatcheFrame -row 1 -column 0 -sticky nswe -pady 2
            }
        } elseif {[$QWIKMD::topGui.nbinput index current] == 0} {
            grid forget $QWIKMD::advGui(atmsel,frame)
        }
        grid conf $frame.tableMode -row 1 -column 0 -sticky nwe -padx 4
        grid conf $frame.strctChck -row 5 -column 0 -sticky nwe -padx 2 -pady 2
        grid conf $frame.buttFrame.butAddTP -row 2 -column 0 -sticky we -pady 4
        grid forget $QWIKMD::advGui(qmregFrame)
    }
}

proc QWIKMD::selResidForSelection {title tableIndexs} {
    QWIKMD::callStrctManipulationWindow
    wm title $QWIKMD::selResGui $title

    if {$title != "Structure Manipulation/Check"} {
        set QWIKMD::tablemode "inspection"
        QWIKMD::tableModeProc
        set state disabled
        if {$QWIKMD::load == 0} {
           set state normal
        } else {
            set tabid [$QWIKMD::topGui.nbinput index current]
            if {$tabid != [lindex [lindex $QWIKMD::selnotbooks 0] 1] || [$QWIKMD::topGui.nbinput.f[expr ${tabid} +1].nb index current] != [lindex [lindex $QWIKMD::selnotbooks 1] 1]} {
                set state normal
            }
        }
        $QWIKMD::selResGui.f1.frameOPT.manipul.buttFrame.butApply configure -state $state
        QWIKMD::lockSelResid 0 
    }
    
    set table $QWIKMD::selresTable 
    $table selection clear 0 end

    if {[llength $tableIndexs] > 0} {
        set resid [$table getcolumns 0]
        set chains [$table getcolumns 2]
        set index ""
        for {set i 0} {$i < [llength $tableIndexs]} { incr i} {
            for {set j 0} {$j< [llength $resid]} {incr j} {
                if {[lindex $tableIndexs $i] == "[lindex $resid $j]_[lindex $chains $j]"} {
                    lappend index $j
                    break
                }
            }
        }
        $table columnconfigure 0 -selectbackground blue -selectforeground white
        $table columnconfigure 1 -selectbackground blue -selectforeground white
        $table columnconfigure 2 -selectbackground blue -selectforeground white
        $table selection set $index
        QWIKMD::rowSelection
        # if {$QWIKMD::selResidSelRep == ""} {
        #     mol addrep $QWIKMD::topMol
        #     set QWIKMD::selResidSelRep [mol repname $QWIKMD::topMol [expr [molinfo $QWIKMD::topMol get numreps] -1] ]
        # }
        # mol modcolor [QWIKMD::getrepnum $QWIKMD::selResidSelRep] $QWIKMD::topMol "Name"
        # mol modselect [QWIKMD::getrepnum $QWIKMD::selResidSelRep] $QWIKMD::topMol $QWIKMD::selResidSel
        # mol modstyle [QWIKMD::getrepnum $QWIKMD::selResidSelRep] $QWIKMD::topMol "Licorice"
    }
    
}
## Open Window to change individual atoms names, residue name and ID's
## to match CHARMM topology files. When QWIKMD::advGui(qmoptions,qmgentopo) == 1, the window will be
## used to generate topologies for QM/MM regions.
proc QWIKMD::editAtomGuiProc {} {
    QWIKMD::save_viewpoint 1
    set tabid [$QWIKMD::topGui.nbinput index current]
    if {[winfo exists $QWIKMD::editATMSGui] != 1} {
        toplevel $QWIKMD::editATMSGui
    } else {
        wm deiconify $QWIKMD::editATMSGui
        return
    }

    grid columnconfigure $QWIKMD::editATMSGui 0 -weight 1
    grid rowconfigure $QWIKMD::editATMSGui 0 -weight 1
    ## Title of the windows
    wm title $QWIKMD::editATMSGui "Edit Atoms" ;# titulo da pagina

    wm protocol $QWIKMD::editATMSGui WM_DELETE_WINDOW {
        QWIKMD::deleteAtomGuiProc
    }

    grid [ttk::frame $QWIKMD::editATMSGui.f1] -row 0 -column 0 -sticky nsew -padx 2 -pady 4
    grid columnconfigure $QWIKMD::editATMSGui.f1 0 -weight 1
    grid columnconfigure $QWIKMD::editATMSGui.f1 1 -weight 1
    grid rowconfigure $QWIKMD::editATMSGui.f1 0 -weight 1

    set selframe "$QWIKMD::editATMSGui.f1"
    grid [ttk::frame $selframe.tableframe] -row 0 -column 0 -sticky nswe -padx 4

    grid columnconfigure $selframe.tableframe 0 -weight 1
    grid rowconfigure $selframe.tableframe 0 -weight 1

    set fro2 $selframe.tableframe
    option add *Tablelist.activeStyle       frame
    
    option add *Tablelist.movableColumns    no

        tablelist::tablelist $fro2.tb \
        -columns { 0 "Index" center
                0 "Resname"  center
                0 "Res ID"   center
                0 "Chain ID"     center
                0 "Atom Name"    center
                0 "Element" center
                0 "Charge" center
                0 "Type" center
                } \
                -yscrollcommand [list $fro2.scr1 set] -xscrollcommand [list $fro2.scr2 set] \
                -showseparators 0 -labelrelief groove -labelcommand {}  -labelbd 1 -selectforeground black\
                -foreground black -background white -state normal -stretch "all" -selectmode extended -stripebackgroun white -exportselection true\
                -editstartcommand QWIKMD::atmStartEdit -editendcommand QWIKMD::atmEndEdit 

    $fro2.tb columnconfigure 0 -selectbackground cyan -width 0 -maxwidth 0 -name Index
    $fro2.tb columnconfigure 1 -selectbackground cyan -width 0 -maxwidth 0 -name Resname
    $fro2.tb columnconfigure 2 -selectbackground cyan -width 0 -maxwidth 0 -editable true -editwindow ttk::entry -name ResID
    $fro2.tb columnconfigure 3 -selectbackground cyan -width 0 -maxwidth 0 -name ChainID
    $fro2.tb columnconfigure 4 -selectbackground cyan -width 0 -maxwidth 0 -editable true -editwindow ttk::combobox -name AtmdNAME
    $fro2.tb columnconfigure 5 -selectbackground cyan -width 0 -maxwidth 0 -name Element
    $fro2.tb columnconfigure 6 -selectbackground cyan -width 0 -maxwidth 0 -name Charge
    $fro2.tb columnconfigure 7 -selectbackground cyan -width 0 -maxwidth 0 -name Type
    
    set QWIKMD::atmsTable $fro2.tb
    grid $fro2.tb -row 0 -column 0 -sticky news
    $fro2.tb configure -height 15 -width 0 -stretch "all"


    ##Scrool_BAr V
    scrollbar $fro2.scr1 -orient vertical -command [list $fro2.tb  yview]
    grid $fro2.scr1 -row 0 -column 1  -sticky ens

    ## Scrool_Bar H
    scrollbar $fro2.scr2 -orient horizontal -command [list $fro2.tb xview]
    grid $fro2.scr2 -row 1 -column 0 -sticky swe

    grid [ttk::frame $selframe.frameInfo] -row 0 -column 1 -sticky nswe -padx 4
    grid columnconfigure $selframe.frameInfo 0 -weight 1
    grid rowconfigure $selframe.frameInfo 0 -weight 1

    grid [ttk::frame $selframe.frameInfo.txtframe] -row 0 -column 0 -sticky nswe -padx 4
    grid columnconfigure $selframe.frameInfo.txtframe 0 -weight 2
    grid rowconfigure $selframe.frameInfo.txtframe 0 -weight 2

    grid [tk::text $selframe.frameInfo.txtframe.text -font TkFixedFont -wrap none -height 1 -bg white -width 50 -height 1 -relief flat -foreground black -yscrollcommand [list $selframe.frameInfo.txtframe.scr1 set] -xscrollcommand [list $selframe.frameInfo.txtframe.scr2 set]] -row 0 -column 0 -sticky wens

        ##Scrool_BAr V
    scrollbar $selframe.frameInfo.txtframe.scr1  -orient vertical -command [list $selframe.frameInfo.txtframe.text yview]
    grid $selframe.frameInfo.txtframe.scr1  -row 0 -column 1  -sticky ens

    ## Scrool_Bar H
    scrollbar $selframe.frameInfo.txtframe.scr2  -orient horizontal -command [list $selframe.frameInfo.txtframe.text xview]
    grid $selframe.frameInfo.txtframe.scr2 -row 1 -column 0 -sticky swe

    set QWIKMD::atmsText "$selframe.frameInfo.txtframe.text"

    $QWIKMD::atmsText configure -font TkFixedFont
    ## widgets necessary to generate topologies
    
    grid [ttk::labelframe $selframe.frameInfo.topoframe -text "Generate Topology"] -row 1 -column 0 -sticky nswe -padx 4 -pady 2
    grid columnconfigure $selframe.frameInfo.topoframe 0 -weight 1
    grid rowconfigure $selframe.frameInfo.topoframe 0 -weight 1
    set QWIKMD::advGui(qmoptions,qmgentopoframe) $selframe.frameInfo.topoframe

    grid [ttk::frame $selframe.frameInfo.topoframe.selres] -row 0 -column 0 -sticky wes -padx 2
    grid columnconfigure $selframe.frameInfo.topoframe.selres 1 -weight 1

    grid [ttk::label $selframe.frameInfo.topoframe.selres.unkreslbl -text "Select\nResidue" -width 7] -row 0 -column 0 -sticky wes -padx 2

    grid [ttk::combobox $selframe.frameInfo.topoframe.selres.unkrescmb -values $QWIKMD::rename -width 10 -state readonly -textvariable QWIKMD::advGui(qmoptions,ressel)] -row 0 -column 1 -sticky ew -padx 2
    set QWIKMD::advGui(qmoptions,ressel) [$selframe.frameInfo.topoframe.selres.unkrescmb get]

    bind $selframe.frameInfo.topoframe.selres.unkrescmb  <<ComboboxSelected>> {
        set QWIKMD::totcharge 0.00
        set chaincol [$QWIKMD::selresTable getcolumns 2]
        set rescol [$QWIKMD::selresTable getcolumns 0]
        set residchain [split $QWIKMD::advGui(qmoptions,ressel) "_"]
        set resindex [lsearch -all $rescol [lindex $residchain 0] ]
        set tbindex ""
        foreach resind $resindex {
            if {[lindex $chaincol $resind] == [lindex $residchain end]} {
                set tbindex $resind
            }
        }
        if {$tbindex != ""} {
            set prev $QWIKMD::tablemode
            set QWIKMD::tablemode "edit"
            $QWIKMD::selresTable selection set $tbindex
            QWIKMD::Apply
            set QWIKMD::tablemode $prev
            QWIKMD::checkresidueTop [$QWIKMD::atmsTable cellcget 0,1 -text] 2 $QWIKMD::editATMSGui
        }
        
        %W selection clear  
    }
    set QWIKMD::advGui(qmoptions,resselcombo) $selframe.frameInfo.topoframe.selres.unkrescmb
    grid [ttk::frame $selframe.frameInfo.topoframe.seltopo] -row 0 -column 1 -sticky we -padx 2
    grid columnconfigure $selframe.frameInfo.topoframe.seltopo 1 -weight 1

    grid [ttk::label $selframe.frameInfo.topoframe.seltopo.trgtfilelb -text "File Name:"] -row 0 -column 0 -sticky w -padx 2
    grid [ttk::entry $selframe.frameInfo.topoframe.seltopo.trgtfilcombo -textvariable QWIKMD::topofilename] -row 0 -column 1 -sticky we -padx 2
    set QWIKMD::topofilename ""

    grid [ttk::frame $selframe.frameInfo.topoframe.totcharge] -row 1 -column 0 -sticky wes -padx 2
    grid columnconfigure $selframe.frameInfo.topoframe.totcharge 1 -weight 1

    grid [ttk::label $selframe.frameInfo.topoframe.totcharge.lbl -text "Total\nCharge" -width 7] -row 0 -column 0 -sticky wes -padx 2
    grid [ttk::entry $selframe.frameInfo.topoframe.totcharge.entry -width 10 -textvariable QWIKMD::totcharge -validate focusout -validatecommand QWIKMD::validateQMTotCharge] -row 0 -column 1 -sticky ew -padx 2

    grid [ttk::frame $selframe.frameInfo.topoframe.genTop] -row 1 -column 1 -sticky we -padx 2
    grid columnconfigure $selframe.frameInfo.topoframe.genTop 0 -weight 1

    grid [ttk::button $selframe.frameInfo.topoframe.genTop.btt -text "Generate Topology" -padding "2 0 2 0" -command QWIKMD::generateTopology] -row 0 -column 0 -sticky we -padx 2

    grid [ttk::frame $selframe.frameInfo.okcancelframe] -row 2 -column 0 -sticky nse -padx 4
    grid columnconfigure $selframe.frameInfo.okcancelframe 0 -weight 1
    grid rowconfigure $selframe.frameInfo.okcancelframe 0 -weight 1
    grid [ttk::button $selframe.frameInfo.okcancelframe.delete -text "Delete" -command {
        set index [$QWIKMD::atmsTable curselection]
        if { $index == -1 || [llength $index] == 0} {
            return
        }
        set atmindex [expr [$QWIKMD::atmsTable cellcget $index,0 -text] -1]
        QWIKMD::deleteAtoms $atmindex $QWIKMD::atmsMol
        lappend QWIKMD::atmsDeleteNames $atmindex
        $QWIKMD::atmsTable delete $index
        graphics $QWIKMD::atmsMol delete [lindex $QWIKMD::atmsLables $atmindex]
    }] -row 0 -column 1 -sticky ws -padx 2
    grid [ttk::button $selframe.frameInfo.okcancelframe.ok -text "Ok" -command QWIKMD::changeAtomNames] -row 0 -column 2 -sticky ws -padx 2
    grid [ttk::button $selframe.frameInfo.okcancelframe.cancel -text "Cancel" -command QWIKMD::cancelAtomNames] -row 0 -column 3 -sticky es -padx 2

    grid [ttk::button $selframe.frameInfo.okcancelframe.savetopo -text "Save Topology" -command {
        global env
        if {[llength $QWIKMD::topofilename] > 0} {
            set resname [$QWIKMD::atmsTable cellcget 0,1 -text]
            if {[QWIKMD::format2Dec [expr fmod($QWIKMD::totcharge,1)]] > 0.00} {
                set answer [tk_messageBox -message "The total charge of the residue is non-integer.\
                 Do you want to proceed with an non-integer charge for this residue?"\
                -title "Residue Charge" -icon info -type yesno -parent $QWIKMD::editATMSGui]
                if {$answer == "no"} {
                    return
                }
            }
            if {[QWIKMD::checkresidueTop $resname 1 $QWIKMD::editATMSGui] == 1} {
                return
            }
            if {[lsearch $QWIKMD::TopList */$QWIKMD::topofilename] > -1} {
                set answer [tk_messageBox -message "Topology file already exist. Do you want to replace it?"\
                 -type yesnocancel -icon info -title "QM Topology File" -parent $QWIKMD::editATMSGui]
                if {$answer == "no" || $answer == "cancel"} {
                    return
                } 
            } 

            if {[file exist ${env(QWIKMDTMPDIR)}/tem_top.rtf] == 1} {
                file copy -force ${env(QWIKMDTMPDIR)}/tem_top.rtf ${env(QWIKMDTMPDIR)}/$QWIKMD::topofilename
                lappend QWIKMD::TopList ${env(QWIKMDTMPDIR)}/$QWIKMD::topofilename
                
                set type QM
                set file ${env(QWIKMDTMPDIR)}/$QWIKMD::topofilename
                set macroindex [lsearch -index 0 $QWIKMD::userMacros $type]

                if { $macroindex == -1} {
                    ## text = {<Molecule Type> <CHRAMM Name> <Residue Name> <Topology File Name>}
                    set txt [list $type $resname $resname ${env(QWIKMDTMPDIR)}/$QWIKMD::topofilename]
                    lappend QWIKMD::userMacros $txt
                } elseif {$macroindex != -1} {
                    set aux [lindex $QWIKMD::userMacros $macroindex]
                    set aux [list [lindex $aux 0] [concat [lindex $aux 1] $resname] [concat [lindex $aux 2] $resname] [concat [lindex $aux 3] ${env(QWIKMDTMPDIR)}/$QWIKMD::topofilename]]
                    lset QWIKMD::userMacros $macroindex $aux
                }
                set topoindex 0
                set found 0
                foreach topo $QWIKMD::topoinfo {
                    set reslist [::Toporead::topology_get resnames $topo]
                    if {[lsearch $reslist $resname] != -1} {
                        set found 1
                        break
                    }
                    incr topoindex
                }
                set newtopo [::Toporead::read_charmm_topology ${env(QWIKMDTMPDIR)}/$QWIKMD::topofilename] 
                if {$found == 1} {
                    lset QWIKMD::topoinfo $topoindex $newtopo
                } else {
                    lappend QWIKMD::topoinfo [join $newtopo]
                }

                if {[lsearch $QWIKMD::ParameterList ${env(QWIKMDTMPDIR)}/$QWIKMD::topofilename] == -1 \
                && [lsearch [$QWIKMD::atmsTable getcolumns 5] "Fe"] != -1} {
                    lappend QWIKMD::ParameterList ${env(QWIKMDTMPDIR)}/$QWIKMD::topofilename
                }

                file delete -force ${env(QWIKMDTMPDIR)}/tem_top.rtf
                tk_messageBox -message "Topology file saved." -type ok -icon info -title "QM Topology File Saved" -parent $QWIKMD::editATMSGui
            } else {
                tk_messageBox -message "Please generate the topology" -type ok -icon warning -title "QM Topology" -parent $QWIKMD::editATMSGui
                return
            }
            # file copy -force ${env(QWIKMDTMPDIR)}/tem_top.rtf ${env(QWIKMDTMPDIR)}/$QWIKMD::topofilename
            
        }
    }] -row 0 -column 0 -sticky ws -padx 2
    set QWIKMD::advGui(qmoptions,savetopo) $selframe.frameInfo.okcancelframe.savetopo 
    ## Hide or show the widgets to generate topologies
    QWIKMD::updateEditAtomWindow
}
####################################################################
## Validate the total charge of the topology being generated in 
## Generate QM Region Topology window
####################################################################
proc QWIKMD::validateQMTotCharge {} {
    set tblsize [$QWIKMD::atmsTable size]
    if {$tblsize > 0} {

    
        if {[string trim $QWIKMD::totcharge] == ""} {
            set QWIKMD::totcharge 0.00
        } else {
            set QWIKMD::totcharge [QWIKMD::format2Dec $QWIKMD::totcharge]
        }
        
        set charge [QWIKMD::format2Dec [expr $QWIKMD::totcharge / [expr $tblsize * 1.0]]]
        set chrglist [lrange [split [string repeat "$charge " [$QWIKMD::atmsTable size]] " "] 0 [expr $tblsize -1]]
        $QWIKMD::atmsTable columnconfigure 6 -text $chrglist
        if {[QWIKMD::format2Dec $QWIKMD::totcharge] != 0.00 } {
            set totaux [QWIKMD::format2Dec [expr $charge * $tblsize]] 
            set diff [QWIKMD::format2Dec [expr $totaux - $QWIKMD::totcharge]]
            set row 0
            set sign "+"
            if {$diff < 0} {
                set sign "-"
            }
            while {$diff != 0.00} {
                set current [$QWIKMD::atmsTable cellcget $row,6 -text]
                $QWIKMD::atmsTable cellconfigure $row,6 -text [QWIKMD::format2Dec [expr $current - ${sign}0.01]]
                set diff [QWIKMD::format2Dec [expr $diff - ${sign}0.01]]
                incr row
                if {$row == $tblsize} {
                    set row 0
                }
            }
        }
        return 1
    } else {
        return 0
    }
}
proc QWIKMD::deleteAtomGuiProc {} {
    wm withdraw $QWIKMD::editATMSGui
    mol delete $QWIKMD::atmsMol
    mol top $QWIKMD::topMol
    QWIKMD::restore_viewpoint 1 
    mol on $QWIKMD::topMol
}
################################################################################################
## Hide/delete widgets and table column necessary to generate missing topologies for the QM/MM
## calculations - charges, new topology name, enable edit the charges and elements
## Add/hide "Generate QM region Topology in the Topology & Parameters Selection"
################################################################################################
proc QWIKMD::updateEditAtomWindow {} {
    if {$QWIKMD::advGui(qmoptions,qmgentopo) == 1} {
        if {[winfo exists $QWIKMD::atmsTable] == 1} {
            if {[$QWIKMD::atmsTable columncget 6 -name] == "Type"} {
                $QWIKMD::atmsTable insertcolumns 6 0 "Charge" center
                validateQMTotCharge     
            }
            $QWIKMD::atmsTable columnconfigure 6 -selectbackground cyan -width 0 -maxwidth 0 -name Charge -editable true -editwindow ttk::entry
            $QWIKMD::atmsTable columnconfigure 5 -editable true -editwindow ttk::combobox 
            $QWIKMD::atmsTable columnconfigure 1 -editable true -editwindow ttk::entry 
            $QWIKMD::atmsTable columnconfigure 2 -editable true -editwindow ttk::entry
            grid configure $QWIKMD::advGui(qmoptions,qmgentopoframe) -row 1 -column 0 -sticky nswe -padx 4 -pady 2
            grid configure $QWIKMD::advGui(qmoptions,savetopo) -row 0 -column 0 -sticky ws -padx 2
            wm title $QWIKMD::editATMSGui "Generate Missing QM Region Topology"
        }
        # if {[winfo exists $QWIKMD::topoPARAMGUI] == 1} {
        # }
    } elseif {$QWIKMD::load == 0} {
        if {[winfo exists $QWIKMD::editATMSGui] == 1 && [winfo exists $QWIKMD::atmsTable] == 1 && [$QWIKMD::atmsTable columncget 6 -name] == "Charge"} {
            $QWIKMD::atmsTable deletecolumns 6
            $QWIKMD::atmsTable columnconfigure 5 -editable false
            $QWIKMD::atmsTable columnconfigure 1 -editable false
            $QWIKMD::atmsTable columnconfigure 2 -editable true -editwindow ttk::entry
            grid forget $QWIKMD::advGui(qmoptions,qmgentopoframe)
            grid forget $QWIKMD::advGui(qmoptions,savetopo)
            wm title $QWIKMD::editATMSGui "Edit Atoms"
        }
        if {[winfo exists $QWIKMD::topoPARAMGUI] == 1} {
            # grid forget $QWIKMD::advGui(qmoptions,qmtopobutton)
        }
    }
    set tabid [$QWIKMD::topGui.nbinput index current]
    if {$tabid == 0 && [winfo exists $QWIKMD::topoPARAMGUI] && [info exists QWIKMD::advGui(qmoptions,qmtopobutton)] == 1} {
        grid forget $QWIKMD::advGui(qmoptions,qmtopobutton)
    } elseif {$tabid == 1 && [winfo exists $QWIKMD::topoPARAMGUI] && [info exists QWIKMD::advGui(qmoptions,qmtopobutton)] == 1} {
        grid configure $QWIKMD::advGui(qmoptions,qmtopobutton) -row 0 -column 4 -sticky ew -pady 2 -padx 2
    }

}
proc QWIKMD::SelResClearSelection {} {
    $QWIKMD::selresTable selection clear 0 end
    for {set i 0} {$i < [llength $QWIKMD::resrepname]} {incr i} {
        mol delrep [QWIKMD::getrepnum [lindex [lindex $QWIKMD::resrepname $i] 1]] $QWIKMD::topMol
    }
    # if {$QWIKMD::selResidSelRep != ""} {
        # mol delrep [QWIKMD::getrepnum $QWIKMD::selResidSelRep] $QWIKMD::topMol
        # set QWIKMD::selResidSelRep ""
        set QWIKMD::selResidSelIndex [list]
    # }
    set QWIKMD::resrepname [list]
    set QWIKMD::selected 0

    if {[wm title $QWIKMD::selResGui] == "Restraints Selection"} {
        set prtclrow [lindex [$QWIKMD::advGui(protocoltb,$QWIKMD::run) editinfo] 1]
        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$prtclrow,restrsel) ""
        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$prtclrow,restrIndex) [list]        
    }

    if {[regexp "QM Region Selection" [wm title $QWIKMD::selResGui]]} {
        set qmID $QWIKMD::advGui(pntchrgopt,qmID)
        set QWIKMD::advGui(qmregopt,atmnumb) 0
        # set QWIKMD::advGui(qmtable,$qmID,qmRegionSelIndex) [list]
        # set QWIKMD::advGui(qmtable,$qmID,qmRegionSel) ""
    }

}
#######################################################################
## Create/open the window to manage the topology+parameters files
## in the QwikMD library created in the home directory
#######################################################################
proc QWIKMD::AddTP {} {
    global env
    if {[winfo exists $QWIKMD::topoPARAMGUI] != 1} {
        toplevel $QWIKMD::topoPARAMGUI
    } else {
        wm deiconify $QWIKMD::topoPARAMGUI
        focus -force $QWIKMD::topoPARAMGUI
        
        QWIKMD::updateEditAtomWindow
        return
    }

    grid columnconfigure $QWIKMD::topoPARAMGUI 0 -weight 2 -minsize 120
    grid rowconfigure $QWIKMD::topoPARAMGUI 0 -weight 2

    ## Title of the windows
    wm title $QWIKMD::topoPARAMGUI "Topology & Parameters Selection"
    wm protocol $QWIKMD::topoPARAMGUI WM_DELETE_WINDOW {
        wm withdraw $QWIKMD::topoPARAMGUI
        if {[winfo exists $QWIKMD::topoPARAMGUI.f1.tableframe.tb] ==1} {
            $QWIKMD::topoPARAMGUI.f1.tableframe.tb selection clear 0 end
        }
     }

    grid [ttk::frame $QWIKMD::topoPARAMGUI.f1] -row 0 -column 0 -sticky nsew -padx 2 -pady 4
    grid columnconfigure $QWIKMD::topoPARAMGUI.f1 0 -weight 1
    grid rowconfigure $QWIKMD::topoPARAMGUI.f1 0 -weight 1

    set selframe "$QWIKMD::topoPARAMGUI.f1"

    grid [ttk::frame $selframe.tableframe] -row 0 -column 0 -sticky nswe -padx 4

    grid columnconfigure $selframe.tableframe 0 -weight 1 
    grid rowconfigure $selframe.tableframe 0 -weight 1

    set fro2 $selframe.tableframe
    option add *Tablelist.activeStyle       frame
    
    option add *Tablelist.movableColumns    no
    option add *Tablelist.labelCommand      tablelist::sortByColumn


        tablelist::tablelist $fro2.tb \
        -columns { 0 "Residue NAME"  center
                0 "CHARMM NAME"  center
                0 "type" center
                0 "Topo & PARM File" center
                } \
                -yscrollcommand [list $fro2.scr1 set] -xscrollcommand [list $fro2.scr2 set] \
                -showseparators 0 -labelrelief groove  -labelbd 1 -selectforeground black\
                -foreground black -background white -state normal -selectmode extended -stretch "all" -stripebackgroun white -exportselection true \
                -editendcommand QWIKMD::editResNameType -forceeditendcommand 0

    $fro2.tb columnconfigure 0 -selectbackground cyan
    $fro2.tb columnconfigure 1 -selectbackground cyan
    $fro2.tb columnconfigure 2 -selectbackground cyan

    $fro2.tb columnconfigure 0 -sortmode integer -name "Resname"
    $fro2.tb columnconfigure 1 -sortmode dictionary -name "CHARMM NAME"
    $fro2.tb columnconfigure 2 -sortmode dictionary -name "type"
    $fro2.tb columnconfigure 3 -sortmode dictionary -name "TopoPArm"
    
    $fro2.tb columnconfigure 0 -width 1 -maxwidth 0 -editable true -editwindow ttk::entry
    $fro2.tb columnconfigure 1 -width 1 -maxwidth 0
    $fro2.tb columnconfigure 2 -width 1 -maxwidth 0 
    $fro2.tb columnconfigure 3 -width 1 -maxwidth 0

    grid $fro2.tb -row 0 -column 0 -sticky news
    $fro2.tb configure -height 6 -width 70

    ##Scrool_BAr V
    scrollbar $fro2.scr1 -orient vertical -command [list $fro2.tb  yview]
     grid $fro2.scr1 -row 0 -column 1  -sticky ens

    ## Scrool_Bar H
    scrollbar $fro2.scr2 -orient horizontal -command [list $fro2.tb xview]
    grid $fro2.scr2 -row 1 -column 0 -sticky swe

    grid [ttk::frame $selframe.buttons] -row 2 -column 0 -sticky nse -padx 2 -pady 4

    grid [ttk::button $selframe.buttons.add -text "+" -padding "1 1 1 1"  -command QWIKMD::addTopParm -width 2] -row 0 -column 1 -sticky e -pady 2
    grid [ttk::button $selframe.buttons.delete -text "-" -padding "1 1 1 1"  -command QWIKMD::deleteTopParm -width 2] -row 0 -column 2 -sticky e -pady 2 
    grid [ttk::button $selframe.buttons.apply -text "Apply" -padding "2 0 2 0" -command QWIKMD::applyTopParm] -row 0 -column 3 -sticky ew -pady 2 -padx 2

    ## Button to open EditAtom Window in Generate topology mode for QM/MM calculations
    set QWIKMD::advGui(qmoptions,qmgentopo) 0
    grid [ttk::button $selframe.buttons.qmtopo -text "Generate QM Region Topology" -padding "2 0 2 0" -command {
        set QWIKMD::tablemode "inspection"
        set QWIKMD::advGui(qmoptions,qmgentopo) 1
        QWIKMD::editAtomGuiProc
        $QWIKMD::atmsText configure -state normal
        $QWIKMD::atmsText delete 1.0 end
        $QWIKMD::atmsTable delete 0 end
        QWIKMD::updateEditAtomWindow
        set QWIKMD::advGui(qmoptions,ressel) ""
    }] -row 0 -column 4 -sticky ew -pady 2 -padx 2
    set QWIKMD::advGui(qmoptions,qmtopobutton) $selframe.buttons.qmtopo    
    QWIKMD::updateEditAtomWindow
    QWIKMD::createInfoButton $selframe.buttons 0 0
    bind $selframe.buttons.info <Button-1> {
        set val [QWIKMD::topparInfo]
        set QWIKMD::link [lindex $val 1]
        QWIKMD::infoWindow toppar [lindex $val 0] [lindex $val 2]
    }
    QWIKMD::addTableTopParm


} 

proc QWIKMD::tableModeProc {} {
    set table $QWIKMD::selresTable
    $QWIKMD::selResGui.f1.frameOPT.manipul.buttFrame.butApply configure -state normal -text "Apply"

    if {$QWIKMD::tablemode == "mutate" || $QWIKMD::tablemode == "prot" || $QWIKMD::tablemode == "rename" || $QWIKMD::tablemode == "type"} {
        $table configure -selectmode single
        $QWIKMD::selResGui.f1.frameOPT.manipul.buttFrame.butApply configure -state disabled
    } elseif {$QWIKMD::tablemode == "inspection"} {
        $QWIKMD::selResGui.f1.frameOPT.manipul.buttFrame.butApply configure -state disabled
        $table configure -selectmode extended
    } else {
        $QWIKMD::selResGui.f1.frameOPT.manipul.buttFrame.butApply configure -state normal
        $table configure -selectmode extended
    }
    if {$QWIKMD::tablemode == "mutate" || $QWIKMD::tablemode == "prot" || $QWIKMD::tablemode == "rename"} {
        $table columnconfigur 3  -editable false
        $table columnconfigure 1 -editable true
    } elseif {$QWIKMD::tablemode == "type"} {
        
        $table columnconfigur 3  -editable true
        $table columnconfigure 1 -editable false
    } elseif {$QWIKMD::tablemode == "edit"} {
        $QWIKMD::selResGui.f1.frameOPT.manipul.buttFrame.butApply configure -state normal -text "Edit"
        $table columnconfigur 3  -editable false
        $table columnconfigure 1 -editable false
        $table configure -selectmode single
    } else {
        $table columnconfigur 3  -editable false
        $table columnconfigure 1 -editable false
    }
    set sel [$QWIKMD::selresTable curselection]
    $table selection set $sel
    QWIKMD::rowSelection
}

############################################################
## Creates the combobox inserted in the resname column in the 
## Select Resid window. The args are automatically generated 
## by the -window configuration option of the tablelist cell 
############################################################
proc QWIKMD::createResCombo {tbl row col text} {
    set w [$tbl editwinpath]
    ttk::style map TCombobox -fieldbackground [list readonly #ffffff]
    set resname [lindex [split $text "->"] 0]
    set resid [$tbl cellcget $row,0 -text]
    set chain [$tbl cellcget $row,2 -text]
    set type [$tbl cellcget $row,3 -text]

    ## Prevent mutations and protonation assignment
    ## for "QM" molecules (molecules without parameters - used for QM/MM)
    ## simulations only.  
    if {$type == "QM" && ($QWIKMD::tablemode == "prot" || $QWIKMD::tablemode == "mutate")} {
        $tbl cancelediting  
        return
    }

    set sel [atomselect top "resid \"$resid\" and chain \"$chain\""]
    set ind end
    if {$QWIKMD::tablemode == "prot"} {
        set ind end
    } elseif {$QWIKMD::tablemode == "mutate"} {
        set ind 2
    }

    set list [split $text "->"]
    set initext ""
    if {$QWIKMD::tablemode == "prot" } {
        if { [llength  $list] > 1} {
            set initext [lindex $list $ind]
        } else {
            set initext [lindex $list 0] 
        }
    } elseif {$QWIKMD::tablemode == "mutate"} {
        set initext [lindex $list 0] 
    } elseif {$QWIKMD::tablemode == "rename"} {
        set initext [lindex [$sel get resname] 0]
    } elseif {$QWIKMD::tablemode == "type"} {
        set initext $text
    }
    
    set QWIKMD::protres(0,0) $initext

    $sel delete
    set QWIKMD::protres(0,1) "$row"
 
    set QWIKMD::protres(0,2) $initext
    if {[llength $list] == 3 } {
        set QWIKMD::protres(0,3) [string trim [lindex $list end] " "]
    } else {
        set QWIKMD::protres(0,3) ""
    }

    switch [$tbl columncget $col -name] {
        ResNAME {
            if {$QWIKMD::tablemode == "prot" && $type == "protein"} {
                set do 0
                set res [string trim [lindex [split $text "->"] end] " "]
                
                switch $res {
                    ASP {
                        set QWIKMD::combovalues {ASP ASPP}
                        set do 1
                    }
                    ASPP {
                        set QWIKMD::combovalues {ASP ASPP}
                        set do 1
                    }
                    GLU {
                        set QWIKMD::combovalues {GLU GLUP}
                        set do 1
                    } 
                    GLUP {
                        set QWIKMD::combovalues {GLU GLUP}
                        set do 1
                    }
                    LYS {
                        set QWIKMD::combovalues {LYS LSN}
                        set do 1
                    }
                    LSN {
                        set QWIKMD::combovalues {LYS LSN}
                        set do 1
                    }
                    CYS {
                        set QWIKMD::combovalues {CYS CYSD}
                        set do 1
                    }
                    CYSD {
                        set QWIKMD::combovalues {CYS CYSD}
                        set do 1
                    }
                    SER {
                        set QWIKMD::combovalues {SER SERD}
                        set do 1
                    }
                    SERD {
                        set QWIKMD::combovalues {SER SERD}
                        set do 1
                    }
                    HIS {
                        set QWIKMD::combovalues {HSD HSE HSP}
                        set do 1
                    }
                    HSD {
                        set QWIKMD::combovalues {HSD HSE HSP}
                        set do 1
                    }
                    HSE {
                        set QWIKMD::combovalues {HSD HSE HSP}
                        set do 1
                    }
                    
                    HSP {
                        set QWIKMD::combovalues {HSD HSE HSP}
                        set do 1
                    } 

                }
                if {$do == 0} {
                    $tbl cancelediting  
                    return
                }
            } elseif {$QWIKMD::tablemode == "mutate" && $type != "water" && $type != "hetero" && [lsearch $QWIKMD::rename ${resid}_$chain] == -1} {
                if {$type == "protein"} {
                    set QWIKMD::combovalues {ALA ARG ASN ASP CYS GLN GLU GLY HSD ILE LEU LYS MET PHE PRO SER THR TRP TYR VAL}
                } elseif {$type == "hetero"} {
                    set QWIKMD::combovalues $QWIKMD::heteronames
                } elseif {$type == "nucleic"} {
                    set QWIKMD::combovalues $QWIKMD::nucleic
                } elseif {$type == "glycan"} {
                    set QWIKMD::combovalues $QWIKMD::carbnames
                } elseif {$type == "lipid"} {
                    set QWIKMD::combovalues $QWIKMD::lipidname
                }
                
                set macroindex [lsearch -index 0 $QWIKMD::userMacros $type]
                if {$macroindex > -1} {
                    if {$type == "protein" || $type == "nucleic" || $type == "lipid"} {
                        set QWIKMD::combovalues [concat $QWIKMD::combovalues [lindex [lindex $QWIKMD::userMacros $macroindex] 1]]
                    } else {
                        set QWIKMD::combovalues [concat $QWIKMD::combovalues [lindex [lindex $QWIKMD::userMacros $macroindex] 2]]
                    }
                } 
                
            } elseif {$QWIKMD::tablemode == "rename" && ($type != "water")} {
                if {$type == "protein" && [lsearch $QWIKMD::rename "${resid}_$chain"] == -1 && [$QWIKMD::topGui.nbinput index current] == 0} {
                    $tbl cancelediting  
                    return
                }
                if {$type == "hetero"} {
                    set QWIKMD::combovalues $QWIKMD::heteronames
                } elseif {$type == "nucleic"} {
                    set QWIKMD::combovalues {GUA ADE CYT THY URA}
                } elseif {$type == "glycan"} {
                    set QWIKMD::combovalues $QWIKMD::carbnames
                } elseif {$type == "lipid"} {
                    set QWIKMD::combovalues $QWIKMD::lipidname
                } elseif {$type == "protein"} {
                    set QWIKMD::combovalues $QWIKMD::reslist
                } else {
                    foreach macro $QWIKMD::userMacros {
                        if {[lindex $macro 0] == $type} {
                            set QWIKMD::combovalues [lindex $macro 2]
                        } 
                    }
                }
                set macroindex [lsearch -index 0 $QWIKMD::userMacros $type]
                if {$macroindex > -1} {
                    if {$type == "protein" || $type == "nucleic" || $type == "lipid" } {
                        set QWIKMD::combovalues [concat $QWIKMD::combovalues [lindex [lindex $QWIKMD::userMacros $macroindex] 1]]
                    } elseif {$type == "glycan" || $type == "hetero"} {
                        set QWIKMD::combovalues [concat $QWIKMD::combovalues [lindex [lindex $QWIKMD::userMacros $macroindex] 2]]
                    } 
                } 
            }   
        }
        Type {
            if {$QWIKMD::tablemode == "type"} {
                if {$type == "protein" && [lsearch $QWIKMD::rename "${resid}_$chain"] == -1 && [$QWIKMD::topGui.nbinput index current] == 0} {
                    $tbl cancelediting  
                    return
                }
                set defVal {protein nucleic glycan lipid hetero}
                set QWIKMD::combovalues $defVal
                foreach macro $QWIKMD::userMacros {
                    if {[lsearch $defVal [lindex $macro 0]] == -1} {
                        lappend QWIKMD::combovalues [lindex $macro 0]
                    }
                }
            }
        }
    }

    set maxwidth 11
    for {set i 0} {$i < [llength $QWIKMD::combovalues]} {incr i} {
        set width [string length [lindex $QWIKMD::combovalues $i]]
        if {$width > $maxwidth} {
            set maxwidth $width
        }
    }
    $tbl columnconfigure $col -width $maxwidth
    $w configure -width $maxwidth -values $QWIKMD::combovalues -state readonly -style TCombobox
    bind $w <<ComboboxSelected>> {
        if {[winfo exists %W]} {
            $QWIKMD::selresTable finishediting
        }   
    }
    if {$QWIKMD::tablemode == "type"} {
        set QWIKMD::prevtype $QWIKMD::protres(0,2)
    }
    set QWIKMD::prevRes $text
   
    set QWIKMD::selected 0
    return $QWIKMD::protres(0,0)
}

proc QWIKMD::EndResCombo {tbl row col text} {
    $tbl finishediting

    return $text
}
############################################################
## Representation combobox in the qwikMD main window
############################################################
proc QWIKMD::mainTableCombosStart {opt tbl row col text} {
    if {$opt == 1} {
        set w [$tbl editwinpath]
    }
     
    switch [$tbl columncget $col -name] {
        Representation {
            set chain [$tbl cellcget $row,0 -text]
            set type [$tbl cellcget $row,2 -text]
            set chaint "$chain and $type"
            set rep "Off NewCartoon QuickSurf Licorice VDW Lines Beads Points DynamicBonds"
            if {$opt == 1} {
                $w configure -values $rep -state readonly -textvariable QWIKMD::index_cmb($chaint,1)
            }
            set indrep 1
            if {$type == "protein" || $type == "nucleic" } {
                set indrep NewCartoon
            } elseif {$type == "hetero" || $type == "glycan" } {
                set indrep Licorice             
            } elseif {$type == "water"} {
                if {[$tbl cellcget $row,0 -text] == "W"} {
                    set indrep Points
                } else {
                    set indrep VDW
                }
            } elseif {$type == "lipid" } {
                set indrep Lines
            } elseif {$type == "QM"} {
                set indrep DynamicBonds
            } else {
                set indrep Licorice
            }
            if {[info exists QWIKMD::index_cmb($chaint,1)] != 1} {
                set QWIKMD::index_cmb($chaint,1) $indrep
            }
            if {[info exists QWIKMD::index_cmb($chaint,3)] != 1} {
                set QWIKMD::index_cmb($chaint,3) $row
            }
            mol modselect [QWIKMD::getrepnum $QWIKMD::index_cmb($chaint,4)] $QWIKMD::topMol $QWIKMD::index_cmb($chaint,5)
            set rep $QWIKMD::index_cmb($chaint,1)
            mol modstyle [QWIKMD::getrepnum $QWIKMD::index_cmb($chaint,4)] $QWIKMD::topMol $rep
            QWIKMD::RenderChgResolution
            if {$opt == 1} {
                bind $w <<ComboboxSelected>> {
                    set table $QWIKMD::topGui.nbinput.f1.tableframe.tb
                    if {[$QWIKMD::topGui.nbinput index current] == 1} {
                        set table $QWIKMD::topGui.nbinput.f2.tableframe.tb
                    }
                    $table finishediting                
                }
            }
           return $QWIKMD::index_cmb($chaint,1)
        }
        Color {
            set chain [$tbl cellcget $row,0 -text]
            set type [$tbl cellcget $row,2 -text]
            set chaint "$chain and $type"
            set sizes [list]
            foreach color $QWIKMD::colorIdMap {
                lappend sizes [string length $color]
            }
            if {$opt == 1} {
                $w configure -values $QWIKMD::colorIdMap -state readonly -textvariable QWIKMD::index_cmb($chaint,2) -width [QWIKMD::maxcalc $sizes]
            }
            if {$type == "protein" || $type == "nucleic"} {
                set chainmol [list]
                foreach str [$tbl getcolumns 0] {
                    if {[lsearch $chainmol $str] == -1} {
                        lappend chainmol $str
                    }
                }
                set index [lindex $QWIKMD::colorIdMap [expr [lsearch $chainmol [lindex $chain 0] ] + 6]]
                if {[lindex $index 1] == "" } {
                    set index "Element"
                }
                set QWIKMD::index_cmb($chaint,2) $index 
            } else {
                set color "Element"
                if {$QWIKMD::prepared == 1} {
                    set color "Name"
                }
                if {$opt == 1} {
                    $w set $color
                } 
                set QWIKMD::index_cmb($chaint,2) $color
            }

            
            if { [string is integer [lindex $QWIKMD::index_cmb($chaint,2) 0]] == 0} {
                mol modcolor [QWIKMD::getrepnum $QWIKMD::index_cmb($chaint,4)] $QWIKMD::topMol "$QWIKMD::index_cmb($chaint,2)"
            } else {
                mol modcolor [QWIKMD::getrepnum $QWIKMD::index_cmb($chaint,4)] $QWIKMD::topMol "ColorID [lindex $QWIKMD::index_cmb($chaint,2) 0]"
            }
            if {$opt == 1} {
                if {$QWIKMD::index_cmb($chaint,2) == "Name" || $QWIKMD::index_cmb($chaint,2) == "Element" || $QWIKMD::index_cmb($chaint,2) == "Structure" || $QWIKMD::index_cmb($chaint,2) == "Throb" || $QWIKMD::index_cmb($chaint,2) == "ResName" || $QWIKMD::index_cmb($chaint,2) == "ResType"} {
                    $w set [lsearch -inline $QWIKMD::colorIdMap $QWIKMD::index_cmb($chaint,2)]
                } else {
                    $w set [lindex $QWIKMD::colorIdMap [expr [lindex $QWIKMD::index_cmb($chaint,2) 0] + 6]]
                }
                bind $w <<ComboboxSelected>> {
                    set table $QWIKMD::topGui.nbinput.f1.tableframe.tb
                    if {[$QWIKMD::topGui.nbinput index current] == 1} {
                        set table $QWIKMD::topGui.nbinput.f2.tableframe.tb
                    }
                    $table finishediting
                }
            }
            return $QWIKMD::index_cmb($chaint,2)    
        }
    }
}
############################################################
## Color combobox in the qwikMD main window
############################################################
proc QWIKMD::mainTableCombosEnd {tbl row col text} {
    set chain [$tbl cellcget $row,0 -text]
    set type [$tbl cellcget $row,2 -text]
    set chain "$chain and $type"
    if {$col == 3} {
        set QWIKMD::index_cmb($chain,1) $text
        mol modselect [QWIKMD::getrepnum $QWIKMD::index_cmb($chain,4)] $QWIKMD::topMol $QWIKMD::index_cmb($chain,5)
        if {$QWIKMD::index_cmb($chain,1) == "Off"} {
            mol showrep $QWIKMD::topMol [QWIKMD::getrepnum $QWIKMD::index_cmb($chain,4)] off
        } else {
            set rep $QWIKMD::index_cmb($chain,1)
            mol modstyle [QWIKMD::getrepnum $QWIKMD::index_cmb($chain,4)] $QWIKMD::topMol $rep
            mol showrep $QWIKMD::topMol [QWIKMD::getrepnum $QWIKMD::index_cmb($chain,4)] on
            QWIKMD::RenderChgResolution
        }
    } else {
        set QWIKMD::index_cmb($chain,2) $text
        if { [string is integer [lindex $QWIKMD::index_cmb($chain,2) 0]] == 0} {
            mol modcolor [QWIKMD::getrepnum $QWIKMD::index_cmb($chain,4)] $QWIKMD::topMol "$QWIKMD::index_cmb($chain,2)"
        } else {
            mol modcolor [QWIKMD::getrepnum $QWIKMD::index_cmb($chain,4)] $QWIKMD::topMol "ColorID [lindex $QWIKMD::index_cmb($chain,2) 0]"
        }

    }
    return $text
}

##############################################
## Update the information according to the 
## Run tab selected (MD,SMD,MDFF or QM/MM)
###############################################
proc QWIKMD::ChangeMdSmd {tabid} {
    if {$tabid == 1} {
        if {[$QWIKMD::topGui.nbinput.f${tabid}.nb index current] == 0} {
            set QWIKMD::run "MD"
        } elseif {[$QWIKMD::topGui.nbinput.f${tabid}.nb index current] == 1} {
            set QWIKMD::run "SMD" 
        }
        set QWIKMD::advGui(qmoptions,qmgentopo) 0
    } elseif {$tabid == 2} {
        set QWIKMD::run [$QWIKMD::topGui.nbinput.f${tabid}.nb tab [$QWIKMD::topGui.nbinput.f${tabid}.nb index current] -text ]
        # set QWIKMD::advGui(qmoptions,qmgentopo) 1
    }
    
    if {$QWIKMD::load == 1} {
        if {$tabid == 2 && [$QWIKMD::advGui(protocoltb,$QWIKMD::run) size] == 0} {
            QWIKMD::fillPrtcTable
        }
        if {[$QWIKMD::topGui.nbinput.f${tabid}.nb index current] != [lindex [lindex $QWIKMD::selnotbooks 1] 1]} {
            QWIKMD::ChangeSolvent
            set tbindex [expr $tabid -1]
            [lindex $QWIKMD::runbtt $tbindex] configure -state disabled
            [lindex $QWIKMD::finishbtt $tbindex]  configure -state disabled
            [lindex $QWIKMD::detachbtt $tbindex]  configure -state disabled
            [lindex $QWIKMD::pausebtt $tbindex]  configure -state disabled
            [lindex $QWIKMD::preparebtt $tbindex] configure -state normal
            # [lindex $QWIKMD::chainMenu $tbindex] configure -state disabled
            $QWIKMD::basicGui(workdir,$tabid) configure -state normal

        } elseif {[expr $tabid -1] == [lindex [lindex $QWIKMD::selnotbooks 0] 1]} {
            set QWIKMD::confFile $QWIKMD::loadprotlist
            set tbindex [expr $tabid -1]
            [lindex $QWIKMD::runbtt $tbindex] configure -state normal
            [lindex $QWIKMD::finishbtt $tbindex]  configure -state normal
            [lindex $QWIKMD::detachbtt $tbindex]  configure -state normal
            [lindex $QWIKMD::pausebtt $tbindex]  configure -state normal
            [lindex $QWIKMD::preparebtt $tbindex] configure -state disabled
            # [lindex $QWIKMD::chainMenu $tbindex] configure -state normal
            $QWIKMD::basicGui(workdir,$tabid) configure -state disabled
        }
    }
    if {$QWIKMD::topMol != ""} {
        
        if {[winfo exists $QWIKMD::selresTable]} {
            $QWIKMD::selresTable selection clear 0 end
        
            if {$QWIKMD::state > 0} {
                return
            } else {
                
                if {$QWIKMD::run == "SMD"} {
                    QWIKMD::checkAnchors
                    
                } else {
                    if {$QWIKMD::pullingrepname != ""} {
                        mol delrep [QWIKMD::getrepnum $QWIKMD::pullingrepname] $QWIKMD::topMol
                        set QWIKMD::pullingrepname ""
                    }
                    if {$QWIKMD::anchorrepname != ""} {
                        mol delrep [QWIKMD::getrepnum $QWIKMD::anchorrepname] $QWIKMD::topMol
                        set QWIKMD::anchorrepname ""
                    }   
                }
            }
        }
        
    }
    set tabid [$QWIKMD::topGui.nbinput index current]
    if {$tabid == 1 && $QWIKMD::run != "MDFF"} {
        set QWIKMD::confFile [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 0]
        set QWIKMD::maxSteps [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 1]
    } elseif {$tabid == 1 && $QWIKMD::run == "MDFF" && $QWIKMD::load == 0} {
        set QWIKMD::advGui(solvent,$QWIKMD::run,0) "Vacuum"
        set QWIKMD::confFile "MDFF"
    }
    if {[winfo exists $QWIKMD::editATMSGui] == 1 || [winfo exists $QWIKMD::topoPARAMGUI] == 1} {
        QWIKMD::updateEditAtomWindow
    } 
    ##############################################
    ## Change info button text between SMD and MD
    ##############################################
    if {$QWIKMD::run == "SMD"} {
        if {$tabid == 1} {
            set QWIKMD::advGui(solvent,minimalbox,$QWIKMD::run) 0
            $QWIKMD::advGui(solvent,minbox,$QWIKMD::run) configure -state disabled   
            bind $QWIKMD::advGui(mdsmdinfo,$QWIKMD::run) <Button-1> {
                set val [QWIKMD::protocolSMDInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow protocolSMDInfo [lindex $val 0] [lindex $val 2]
            }   
        } else {
            bind $QWIKMD::basicGui(mdsmdinfo,$QWIKMD::run) <Button-1> {
                set val [QWIKMD::protocolSMDInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow protocolSMDInfo [lindex $val 0] [lindex $val 2]
            }
        }
        
    } elseif {$QWIKMD::run == "MD"} {
        if {$tabid == 1} {
            bind $QWIKMD::advGui(mdsmdinfo,$QWIKMD::run) <Button-1> {
                set val [QWIKMD::protocolMDInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow protocolMDInfo [lindex $val 0] [lindex $val 2]
            }
        } else {
            bind $QWIKMD::basicGui(mdsmdinfo,$QWIKMD::run) <Button-1> {
                set val [QWIKMD::protocolMDInfo]
                set QWIKMD::link [lindex $val 1]
                QWIKMD::infoWindow protocolMDInfo [lindex $val 0] [lindex $val 2]
            }
        }
    }  elseif {$QWIKMD::run == "MDFF"} {
        bind $QWIKMD::advGui(mdsmdinfo,$QWIKMD::run) <Button-1> {
            set val [QWIKMD::protocolMDFFInfo]
            set QWIKMD::link [lindex $val 1]
            QWIKMD::infoWindow protocolMDFFInfo [lindex $val 0] [lindex $val 2]
        }
    } elseif {$QWIKMD::run == "QM/MM"} { 
        bind $QWIKMD::advGui(mdsmdinfo,$QWIKMD::run) <Button-1> {
            set val [QWIKMD::protocolQMMMInfo]
            set QWIKMD::link [lindex $val 1]
            QWIKMD::infoWindow protocolQMMMInfo [lindex $val 0] [lindex $val 2]
        }
    }
    QWIKMD::ChangeSolvent
}

proc QWIKMD::ChangeSolvent {} {
    global env
    set tabid [$QWIKMD::topGui.nbinput index current]
    # if {$QWIKMD::prepared==1} {
    #     if {$tabid == [lindex [lindex $QWIKMD::selnotbooks 0] 1] && \
    #         [$QWIKMD::topGui.nbinput.f[expr ${tabid} +1].nb index current] == [lindex [lindex $QWIKMD::selnotbooks 1] 1]} {
    #         return
    #     } 
    # }
    if {[info exists QWIKMD::basicGui(solvent,$QWIKMD::run,0)] == 1 && $tabid == 0} {
        if {$QWIKMD::basicGui(solvent,$QWIKMD::run,0) == "Implicit"} {
            if {$QWIKMD::load == 0} {
                $QWIKMD::basicGui(saltions,$QWIKMD::run) configure -state disabled
                $QWIKMD::basicGui(saltconc,$QWIKMD::run) configure -state normal
            }
            if {[winfo exists $QWIKMD::advGui(analyze,advance,interradio)] == 1} {
                $QWIKMD::advGui(analyze,advance,interradio) configure -state disabled
            }
            if {[winfo exists $QWIKMD::advGui(analyze,advance,pressbtt)] == 1 && $tabid == 0} {
                $QWIKMD::advGui(analyze,advance,pressbtt) configure -state disabled
            }
            if {[winfo exists $QWIKMD::advGui(analyze,advance,volbtt)] == 1 && $tabid == 0} {
                $QWIKMD::advGui(analyze,advance,volbtt) configure -state disabled
            }
        } else {
            if {$QWIKMD::load == 0} {
                $QWIKMD::basicGui(saltions,$QWIKMD::run) configure -state readonly
                $QWIKMD::basicGui(saltconc,$QWIKMD::run) configure -state normal
            }

            if {[winfo exists $QWIKMD::advGui(analyze,advance,interradio)] == 1} {
                $QWIKMD::advGui(analyze,advance,interradio) configure -state normal
            }
            if {[winfo exists $QWIKMD::advGui(analyze,advance,pressbtt)] == 1 && $tabid == 0} {
                $QWIKMD::advGui(analyze,advance,pressbtt) configure -state normal
            }
            if {[winfo exists $QWIKMD::advGui(analyze,advance,volbtt)] == 1 && $tabid == 0} {
                $QWIKMD::advGui(analyze,advance,volbtt) configure -state normal
            }
        }
    }
    
    if {[info exists QWIKMD::advGui(solvent,$QWIKMD::run,0) ] == 1 && $tabid == 1} {
        
        if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Implicit" || $QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Vacuum"} {
           

            if {[winfo exists $QWIKMD::advGui(analyze,advance,interradio)] == 1} {
                $QWIKMD::advGui(analyze,advance,interradio) configure -state disabled
            }
            if {$QWIKMD::load == 0} {
                $QWIKMD::advGui(saltions,$QWIKMD::run) configure -state disabled 
                $QWIKMD::advGui(solvent,boxbuffer,$QWIKMD::run,entry) configure -state disabled
                set QWIKMD::advGui(solvent,minimalbox,$QWIKMD::run) 0
                $QWIKMD::advGui(solvent,minbox,$QWIKMD::run) configure -state disabled 
            }      
            if {$QWIKMD::run != "MDFF"} {
                set ensemble [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 3]
                set indexes [lsearch -all $ensemble "NpT"]
                if {[llength $indexes] > 0} {
                    for {set i 0} {$i < [llength $indexes]} {incr i} {
                        lset ensemble [lindex $indexes $i] "NVT"
                        $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure [lindex $indexes $i],5 -editable false
                        $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure [lindex $indexes $i],5 -foreground grey -selectforeground grey
                    }
                    $QWIKMD::advGui(protocoltb,$QWIKMD::run) columnconfigure 3 -text $ensemble  
                }
            }
            if {($QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Vacuum" || $QWIKMD::run == "MDFF") && $QWIKMD::load == 0} {
                $QWIKMD::advGui(saltconc,$QWIKMD::run) configure -state disabled
            }
            if {[winfo exists $QWIKMD::advGui(analyze,advance,pressbtt)] == 1 && $tabid == 1} {
                $QWIKMD::advGui(analyze,advance,pressbtt) configure -state disabled
            }
            if {[winfo exists $QWIKMD::advGui(analyze,advance,volbtt)] == 1 && $tabid == 1} {
                $QWIKMD::advGui(analyze,advance,volbtt) configure -state disabled
            }
            
        } else {
            if {$QWIKMD::load == 0} {
                if {($QWIKMD::run != "MDFF" && $QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Implicit") || $QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Explicit"} {
                    $QWIKMD::advGui(saltions,$QWIKMD::run) configure -state readonly 
                }
                $QWIKMD::advGui(saltconc,$QWIKMD::run) configure -state normal
                $QWIKMD::advGui(solvent,boxbuffer,$QWIKMD::run,entry) configure -state readonly
                if {$QWIKMD::run != "SMD"} {
                    $QWIKMD::advGui(solvent,minbox,$QWIKMD::run) configure -state normal
                }
                if {$QWIKMD::run != "MDFF"} {
                    set ensemble [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 3]
                    
                    for {set i 0} {$i < [llength $ensemble]} {incr i} {
                        lset ensemble $i "NpT"
                        if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$i,lock) == 0} {
                            $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $i,4 -editable true
                            $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $i,5 -editable true
                            $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $i,5 -foreground black -selectforeground black   
                        }
                        
                    }
                    $QWIKMD::advGui(protocoltb,$QWIKMD::run) columnconfigure 3 -text $ensemble
                }
            }
            if {[winfo exists $QWIKMD::advGui(analyze,advance,interradio)] == 1} {
                $QWIKMD::advGui(analyze,advance,interradio) configure -state normal
            }
           
            if {[winfo exists $QWIKMD::advGui(analyze,advance,pressbtt)] == 1 && $tabid == 1} {
                $QWIKMD::advGui(analyze,advance,pressbtt) configure -state normal
            }
            if {[winfo exists $QWIKMD::advGui(analyze,advance,volbtt)] == 1 && $tabid == 1} {
                $QWIKMD::advGui(analyze,advance,volbtt) configure -state normal
            }
        }
        if {$QWIKMD::membraneFrame != ""} {
            set QWIKMD::advGui(solvent,minimalbox,$QWIKMD::run) 0
            $QWIKMD::advGui(solvent,minbox,$QWIKMD::run) configure -state disabled   
        }
    }
    # Events related to the protocol rows in the protocol table
    # Not applicable to MDFF tab
    if {$tabid == 1 && $QWIKMD::run != "MDFF" && $QWIKMD::load == 0} {
        set protocolIDS [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 0]
        set values {Minimization Annealing Equilibration MD SMD QMMM-Min QMMM-Ann QMMM-Equi QMMM}
        set protocolIndex 0
        foreach prot $protocolIDS {
            set delete 1
            set index [lsearch $values [file root $prot]]
            if {$index == -1} {
                set tempLib ""
                set do [catch {glob ${env(QWIKMDFOLDER)}/templates/$QWIKMD::advGui(solvent,$QWIKMD::run,0)/[file root ${prot}].conf} tempLib]
                if {$do == 0} {
                    set delete 0
                } else {
                    set tempLib ""
                    set do [catch {glob ${env(QWIKMDTMPDIR)}/${prot}.conf} tempLib]
                    if {$do == 0} {
                        set delete 0
                    }
                }
            } elseif {$index != -1} {
                set delete 0
            }
            if {$delete == 1} {
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) selection set $protocolIndex
                QWIKMD::deleteProtocol
                $QWIKMD::advGui(protocoltb,$QWIKMD::run) selection clear 0 end
                QWIKMD::ChangeSolvent
            }
            incr protocolIndex
        }       
    }
}

##############################################
## Update the Start MD button with the current 
## step (QWIKMD::state)
###############################################

proc QWIKMD::RunText {} {
    set text ""
    set tabid [$QWIKMD::topGui.nbinput index current]

    if {$tabid == 0} {
        if {[string match "*equilibration*" [lindex $QWIKMD::prevconfFile $QWIKMD::state ] ] > 0} {
            set text "Equilibration Simulation $QWIKMD::state"
        } elseif {[string match "*_production_smd_*" [lindex $QWIKMD::prevconfFile $QWIKMD::state ] ] > 0 || [string match "*_production_smd_*" [lindex $QWIKMD::prevconfFile [expr $QWIKMD::state -1] ] ] > 0} {
            set text "Production SMD Simulation $QWIKMD::state"
        } else {
            set text "Production Simulation $QWIKMD::state"
        }
    } else {
        set text "[lindex $QWIKMD::prevconfFile $QWIKMD::state ] Simulation "
    }
    
    return $text
}

##############################################
## Secondary structure colors caption based on
## TimeLine
###############################################

proc QWIKMD::drawColScale {w} {
    #local hard coding for current placement, later should make this visible externally
    set xPos 7 
    set yPos 3
    set valsYPos 7
    set valText 40
    set barTop 19
    set barBottom 34
    set caption [list "Turn" "Beta Extended" "Beta Bridge" "Alpha-Helix" "3-10 Helix" "Pi-Helix" "Coil"]
    
    
    grid [ttk::frame $w.colscale] -row 0 -column 0
    grid columnconfigure $w.colscale 2 -weight 1
    set prevNameIndex -1
    set size [llength $caption]
    set names [list T E B H G I C]
     
    for {set yrect 0} {$yrect < $size} {incr yrect} {
        
        set curName [lindex $names  $yrect]
        set curcaption [lindex $caption  $yrect]
        set hexcols [QWIKMD::chooseColor $curName]
            
        set hexred [lindex $hexcols 0]
        set hexgreen [lindex $hexcols 1]
        set hexblue [lindex $hexcols 2]
        grid [ttk::label $w.colscale.${yrect}1 -text "$curName" -anchor center] -row $yrect -column 0 -sticky we
        grid [label $w.colscale.${yrect}2 -bg \#${hexred}${hexgreen}${hexblue} -width 3] -row $yrect -column 1 -sticky w -padx 4
        grid [ttk::label $w.colscale.${yrect}3 -text $curcaption] -row $yrect -column 2 -sticky ew
    }
    return $w.colscale
}
##############################################
## Secondary strucutre colors caption based on
## TimeLine
###############################################
proc QWIKMD::chooseColor {intensity} {

  set field_color_type s 
  
  switch -exact $field_color_type {         
    s {
      if { [catch {
        switch $intensity {

          B {set red 180; set green 180; set blue 0}
          C {set red 255; set green 255; set blue 255}
          E {set red 255; set green 255; set blue 100}
          T {set red 70; set green 150; set blue 150}
          G {set red 20; set green 20; set blue 255}
          H {set red 235; set green 130; set blue 235}
          I {set red 225; set green 20; set blue 20}
          default {set red 100; set green 100; set blue 100}
        }
        
      } ] 
         } { #badly formatted file, intensity may be a number
        set red 0; set green 0; set blue 0 
      }
    }
    default {
      set c $colorscale(choice)
      set red $colorscale($c,$intensity,r)
      set green $colorscale($c,$intensity,g)
      set blue $colorscale($c,$intensity,b)
   } 
  }
  
  #convert red blue green 0 - 255 to hex
  set hexred     [format "%02x" $red]
  set hexgreen   [format "%02x" $green]
  set hexblue    [format "%02x" $blue]
  set hexcols [list $hexred $hexgreen $hexblue]

  return $hexcols
}

proc QWIKMD::BrowserButt {} {
    set fil ""
    set fil [tk_getOpenFile -title "Open Molecule:" ]
    
    if {$fil != ""} {
        set QWIKMD::inputstrct $fil
    }
    
}

##############################################
## Update the table in the qwikMD main window 
## with new molecule, or when the type of molecules
## is changed in the Select Resid Window 
## Here is when the macros as set for the first time
## qwikmd_glycan qwikmd_nucleic and qwikmd_protein
###############################################
proc QWIKMD::mainTable {tabid} {
    array unset QWIKMD::chains *
    array unset QWIKMD::index_cmb *
    array set QWIKMD::index_cmb ""
    array set QWIKMD::chains ""

    while {[molinfo $QWIKMD::topMol get numreps] !=  0 } {
        mol delrep [expr [molinfo $QWIKMD::topMol get numreps] -1 ] $QWIKMD::topMol
        
    }
    set sel [atomselect $QWIKMD::topMol "all and not name QWIKMDDELETE"]

    $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb configure -state normal
    $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb delete 0 end

    
    set atomindex 0
    set macrosstr [list]
    set defVal {protein nucleic glycan lipid hetero}
    foreach macros $QWIKMD::userMacros {
        if {[lsearch $defVal [lindex $macros 0]] == -1 } {
            lappend macrosstr [lindex $macros 0] 
        }   
    }
    set numfram [molinfo $QWIKMD::topMol get numframes]
    $QWIKMD::topGui.nbinput.f$tabid.selframe.mNMR.nmr delete 0 end
    for {set i 0} {$i < $numfram} {incr i} {
        
        $QWIKMD::topGui.nbinput.f$tabid.selframe.mNMR.nmr add radiobutton -label "$i" -variable QWIKMD::nmrstep -command {
            molinfo $QWIKMD::topMol set frame $QWIKMD::nmrstep
        }
    }

    set listMol [list]
    foreach chain [$sel get chain] protein [$sel get qwikmd_protein] nucleic [$sel get qwikmd_nucleic] glycan [$sel get qwikmd_glycan] lipid [$sel get qwikmd_lipid] hetero [$sel get qwikmd_hetero]\
     water [$sel get water] macros [$sel get $macrosstr] residue [$sel get residue] {
        lappend listMol [list $chain $protein $nucleic $glycan $lipid $hetero $water $macros $residue]
    }
    set listMol [lsort -unique $listMol]
    set listMol [lsort -index 8 -integer -increasing $listMol]
    set labels [list]
    foreach listEle $listMol {
        set chain [lindex $listEle 0]
        set protein [lindex $listEle 1]
        set nucleic [lindex $listEle 2]
        set glycan [lindex $listEle 3]
        set lipid [lindex $listEle 4]
        set hetero [lindex $listEle 5]
        set water [lindex $listEle 6]
        set macros [lindex $listEle 7]

        set type "protein"
        set typesel "qwikmd_protein"
        
        if {$protein == 1 && $macros == 0} {
            set type "protein"
            set typesel "qwikmd_protein"
        } elseif {$nucleic == 1 && $macros != 1} {
            set type "nucleic"
            set typesel "qwikmd_nucleic"
        } elseif {$glycan == 1 && $macros != 1} {
            set type "glycan"
            set typesel "qwikmd_glycan"
        } elseif {$lipid == 1 && $macros != 1} {
            set type "lipid"
            set typesel "qwikmd_lipid"
        } elseif {$water == 1} {
            set type "water"
            set typesel "water"
        } elseif {$macros == 1} {
            set macroName [lindex $macrosstr [lsearch $macros 1]]
            set type $macroName
            set typesel $macroName
        } elseif {$hetero == 1 && $macros != 1} {
            set type "hetero"
            set typesel "qwikmd_hetero"
        }
        if {[lsearch -exact $labels "$chain $typesel"] != -1} {continue}
        set txt "$chain $typesel"
        lappend labels $txt 
    }
    set listMol [list]
    $sel delete

    $QWIKMD::topGui.nbinput.f$tabid.selframe.mCHAIN.chain delete 0 end
    set typeaux ""
    set lineindex 0
    for {set i 0} {$i < [llength $labels]} {incr i} {
        set type [lindex [lindex $labels $i] 1]
        set chain [lindex [lindex $labels $i] 0]
        regsub -all "qwikmd_" $type "" typeaux
        set column 0
        if {[expr $i % 20] == 0} {
            set column 1
        }
        $QWIKMD::topGui.nbinput.f$tabid.selframe.mCHAIN.chain add checkbutton -label "$chain and $typeaux"  -columnbreak $column -variable QWIKMD::chains($i,0) -command QWIKMD::selectChainType

        set QWIKMD::chains($i,1) "$chain and $typeaux"

        set selaux [atomselect $QWIKMD::topMol "chain \"$chain\" and $type"]
        set residues [lsort -unique -integer [$selaux get resid]]
        $selaux delete
        set min [lindex $residues 0]
        set max [lindex $residues end]
        
        set QWIKMD::chains($i,2) "[format %0.0f ${min}] - [format %0.0f ${max}]"
        
        if {[info exists QWIKMD::index_cmb($QWIKMD::chains($i,1),5)] != 1} {
            set auxstrng ""
            if {$type == "protein" || $type == "nucleic" } {
                set auxstrng "chain \"$chain\" and qwikmd_${type}"
            } elseif {$type == "hetero" || $type == "glycan" } {            
                set auxstrng "chain \"$chain\" and qwikmd_${type}"
            } elseif {$type == "water"} {
                set auxstrng "chain \"$chain\" and $type"
            } elseif {$type == "lipid" } {
                set auxstrng "chain \"$chain\" and qwikmd_${type}"  
            } else {
                set auxstrng "chain \"$chain\" and $type"
            }
            set QWIKMD::index_cmb($QWIKMD::chains($i,1),5) $auxstrng
        }
        if {$chain == "W" && $type == "water"} {
            set QWIKMD::chains($i,0) 0
        } elseif {$chain == "I" && $typeaux == "hetero"} {
            set selcur [atomselect $QWIKMD::topMol "chain I"]
            set res [$selcur get ion]
            if {$res != ""} {
                set QWIKMD::chains($i,0) 0
            }
            $selcur delete
        } else {
            $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb insert end [list $chain "[format %0.0f ${min}] - [format %0.0f ${max}]" $typeaux "aux" "aux"]
            mol addrep $QWIKMD::topMol
            set QWIKMD::index_cmb($QWIKMD::chains($i,1),4) [mol repname $QWIKMD::topMol [expr [molinfo $QWIKMD::topMol get numreps] -1] ]

            $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb cellconfigure $lineindex,3 -text [QWIKMD::mainTableCombosStart 0 $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb $lineindex 3 "aux"]
            $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb cellconfigure $lineindex,4 -text [QWIKMD::mainTableCombosStart 0 $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb $lineindex 4 "aux"]
            incr lineindex
            set QWIKMD::chains($i,0) 1

            set sel [atomselect $QWIKMD::topMol $QWIKMD::index_cmb($QWIKMD::chains($i,1),5)]
            set res [$sel get index]
            $sel delete
            if {$res == ""} {
                set QWIKMD::chains($i,0) 0
            } 
            update idletasks
        }
    }
    set menu $QWIKMD::topGui.nbinput.f$tabid.selframe.mCHAIN.chain.select   
    if {[winfo exists $menu] == 0} {
        menu $menu
        proc selectAllNon {opt} {
            set val 1
            if {$opt != "all"} {
                set val 0
            }
            set length [expr [array size QWIKMD::chains] /3]
            for {set i 0} {$i < $length} {incr i} {
                set QWIKMD::chains($i,0) $val
            }
            QWIKMD::selectChainType
        }
        $menu add command -label "All" -command {QWIKMD::selectAllNon "all"}
        $menu add command -label "None" -command {QWIKMD::selectAllNon "none"}
    }
    $QWIKMD::topGui.nbinput.f$tabid.selframe.mCHAIN.chain add cascade -menu $menu -label "Select"
    
    
    

    

    set QWIKMD::warnresid 0
    mouse mode rotate
    return 1
}

proc QWIKMD::selectChainType {} {
    set tabid [$QWIKMD::topGui.nbinput index current]
    set level basic
    if {$tabid == 1} {
        set level advanced
    }
    [lindex $QWIKMD::chainMenu $tabid] configure -state disabled
    QWIKMD::reviewTable [expr [lsearch [$QWIKMD::topGui.nbinput tabs] [$QWIKMD::topGui.nbinput select]] + 1 ]
    set length [expr [array size QWIKMD::chains] /3]
    for {set i 0} {$i < $length} {incr i} {
        set type [lindex $QWIKMD::chains($i,1) 2]
        set chain [lindex $QWIKMD::chains($i,1) 0]
        set rows [$QWIKMD::selresTable get 0 end]
        set index [lsearch -all [$QWIKMD::selresTable get 0 end] "*$chain $type"]
        foreach idx $index {
            if {$QWIKMD::chains($i,0) == 0} {
                $QWIKMD::selresTable rowconfigure $idx -hide 1
            } else {
                $QWIKMD::selresTable rowconfigure $idx -hide 0
            }
        }
    }
    [lindex $QWIKMD::chainMenu $tabid] configure -state normal
}

proc QWIKMD::LoadButt {fil} {
    
    if {[file isfile [lindex $fil 0] ] == 1} {
        set QWIKMD::topMol [mol new [lindex $fil 0] waitfor all]
        if {[llength $fil] > 1} {   
            mol addfile [lindex $fil 1] waitfor all
        } 
    } else {
        set QWIKMD::inputstrct [string trim $fil " "]
        set QWIKMD::topMol [mol new $QWIKMD::inputstrct waitfor all]
    }
    set QWIKMD::nmrstep 0
    molinfo $QWIKMD::topMol set frame $QWIKMD::nmrstep
    update
}   


proc QWIKMD::tableSearchCheck {resid tbl row column text } { 
    if {[$tbl cellcget $row,0 -text] == $resid && [$tbl rowcget $row -hide] == 0} {
        return 1
    } else {
        return 0
    }
}

## Check if any patch was declared and its format
proc QWIKMD::validatePatchs {} {
    set nlines [expr [lindex [split [$QWIKMD::selresPatcheText index end] "."] 0] -1]
    set patchtext [split [$QWIKMD::selresPatcheText get 1.0 $nlines.end] "\n"]
    set patchaux [list]
    if {[lindex $patchtext 0] != ""} {
        foreach patch $patchtext {
            if {$patch != ""} {
                if {[llength $patch] == 3 || [llength $patch] == 5} {
                    lappend patchaux $patch
                } else {
                    tk_messageBox -message "The modification list is not in the correct format.\nPlease revise and prepare again." \
                    -type ok -icon warning -title "Modifications (Patches) List" -parent $QWIKMD::topGui
                    set QWIKMD::patchestr ""
                    return 
                }
            }
        }
        set QWIKMD::patchestr $patchaux
    }
}
##############################################
## Proc to prepare psf and pdb file and all the
## config files
###############################################
proc QWIKMD::PrepareBttProc {file} {
    global env
    set rtrn 0
    set tabid [$QWIKMD::topGui.nbinput index current]
    set resTable $QWIKMD::selresTable


    if {$QWIKMD::rename != ""} {
        for {set i 0} {$i < [llength $QWIKMD::rename]} {incr i} {
            set residchain [split [lindex $QWIKMD::rename $i] "_" ]
            set resid [lindex $residchain 0]
            set chain [lindex $residchain end]
            if {[lsearch -exact $QWIKMD::renameindex [lindex $QWIKMD::rename $i]] == -1 \
                && [lsearch -exact $QWIKMD::delete [lindex $QWIKMD::rename $i]] == -1 && [$resTable searchcolumn 2 $chain -check [list QWIKMD::tableSearchCheck $resid] ] > -1 } {
                set rtrn 1
                break
            }
        }
    }

    if {$QWIKMD::warnresid == 1} {
        if {[lindex $QWIKMD::topoerror 0] > 0} {
            tk_messageBox -message "One or more residues could not be identified\nPlease rename or \
            delete them in \"Structure Manipulation/Check\" window" -title "Residues Topology" -icon warning -type ok -parent $QWIKMD::topGui 
        } else {
            tk_messageBox -message "One or more warnings are still active.\nPlease go \
            to \"Structure Manipulation/Check\" window" -title "Structure Check Warnings" -type ok -parent $QWIKMD::topGui
        }
        return
    }

    if {$tabid == 1} {
        QWIKMD::validatePatchs
    }
    
    if {$QWIKMD::run == "SMD" && ($QWIKMD::anchorRessel == "" || $QWIKMD::pullingRessel == "")} {
        tk_messageBox -message "Anchor/Pulling residues were not defined. Please select them pressing\
         \"Anchor Residues\" and \"Pulling Residues\" buttons" -title "Anchor/Pulling Residues" -icon warning -type ok -parent $QWIKMD::topGui 
        return
    }

    if {$QWIKMD::run == "QM/MM"} {
        if {[QWIKMD::checkQMPckgPath 1] == 1} {
            return
        }
        set atomnums [$QWIKMD::advGui(qmtable) getcolumns 1]
        if {[lsearch $atomnums "0"] != -1 || [llength $atomnums] == 0} {
            tk_messageBox -message "Please make sure that all QM regions have one or more atoms defined."\
             -title "QM Region definition" -icon warning -type ok -parent $QWIKMD::topGui
            return
        } else {
            set return 0
            for {set qmID 1} {$qmID <= [$QWIKMD::advGui(qmtable) size]} {incr qmID} {
                if {[QWIKMD::reviewQMCharges $qmID] == 1} {
                    set return 1
                    break
                }
            }
            if {$return == 1} {
                return
            }
        }
        if {$QWIKMD::advGui(qmoptions,lssmode) == "Center of Mass"} {
            set sellist [$QWIKMD::advGui(qmtable) getcolumns 4]
            set index [lsearch $sellist "none"]
            if {$index  != -1} {
                tk_messageBox -message "Please assign a valid atom selection to all COM in the \
                QM Regions table." -title "COM Selections" -icon warning -type ok -parent $QWIKMD::topGui
                return
            }
        }
    }
    
    if {$file != ""} {
        if {$QWIKMD::run == "QM/MM"} {
            if {[regexp " " $file] != 0} {
                tk_messageBox -message "The QM/MM interface does not support file locations containing space characters. \
                Please provide another file name and/or destination." -type ok -title "Output Path with Spaces." -icon warning -parent $QWIKMD::topGui
                return 
            }
        }
        if {$QWIKMD::load == 1 && [file rootname $file] == $QWIKMD::outPath} {
            tk_messageBox -message "The destination folder is the same as the source folder. Please select other folder."\
             -title "Destination Folder" -icon warning -type ok -parent $QWIKMD::topGui
            return
        }   

        set overwrite [QWIKMD::checkOutPath [file rootname $file]]
        if {$overwrite == "no"} {
            return
        }
        set outputfoldername [file rootname $file]
        set prevoutputfolder ""
        set loadprevtext ""
        set frame -1
        if {$QWIKMD::load == 1} {
            ## In the case of continuing a simulation from a trajectory
            ## necessary to redefine the QWIKMD::outPath for the QWIKMD::LoadOptBuild proc
            set prevoutputfolder ${QWIKMD::outPath}
            # set curpath $QWIKMD::outPath

            set QWIKMD::outPath ${prevoutputfolder}

            set prevsim [file tail ${QWIKMD::outPath}]
            append loadprevtext [QWIKMD::loadPrevious $prevsim]

            QWIKMD::LoadOptBuild $tabid "restart.coor"
            $QWIKMD::topGui.nbinput select $tabid
            
             
            if {$QWIKMD::loadprotlist == "Cancel"} {
                ## not a duplication of code, just make sure to return to the initial folder before the return
                # set QWIKMD::outPath $prevoutputfolder
                cd $prevoutputfolder
                return
            } else {
                
                if {$QWIKMD::curframe > 0} {
                    set psf ""
                    catch {glob ${QWIKMD::outPath}/run/*.psf} psf
                    set list {"nowater" "_noions" "_noh"}
                    set found 0
                    foreach str $list {
                        set index [lsearch -regexp $psf (?i)$str]
                        if {$index != -1} {
                            set found 1
                            set psf [lreplace $psf $index $index]
                        }
                    }
                    if {$found == 1} {
                        set QWIKMD::topMol [mol new ${psf}]
                    }
                    animate delete beg 0 end [molinfo top get numframes] skip 0 top 
                    if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Explicit"} {
                        pbc box -off
                    }
                    set loadstartfile ${prevoutputfolder}/run/${QWIKMD::loadprotlist}.restart
                    mol addfile ${QWIKMD::loadprotlist}.restart.coor waitfor all
                    if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Explicit"} {
                        pbc readxst ${QWIKMD::loadprotlist}.restart.xsc
                        pbc box -on
                    }  
                } else {
                    set frame [molinfo top get frame]
                } 
                
                append loadprevtext [QWIKMD::restartFromPrevious $prevsim $frame] 
                # else {
                #     ## Use the QWIKMD::lastframe to figure out where the frame is located
                #     # QWIKMD::lastframe
                # }
                cd $prevoutputfolder
            }
        }

        $QWIKMD::topGui configure -cursor watch; update 
        set numtabs [llength [$QWIKMD::topGui.nbinput tabs]]
        for {set i 0} {$i < $numtabs} {incr i} {
            if {$tabid != $i} {
                $QWIKMD::topGui.nbinput tab $i -state disabled
            }
        }

        set QWIKMD::outPath "${outputfoldername}"

        if {[file exists $outputfoldername]== 1} {
            cd $::env(VMDDIR)
            file delete -force -- $outputfoldername
        }
        file mkdir $outputfoldername

        set QWIKMD::textLogfile [open "${outputfoldername}/[file tail $outputfoldername].infoMD" w+] 

        puts $QWIKMD::textLogfile [QWIKMD::introText]

        QWIKMD::defaultIMDbtt $tabid disabled

        #$QWIKMD::runbtt configure -state disabled
        if {$QWIKMD::load == 0} {
            for {set i 0} {$i < [llength $QWIKMD::delete]} {incr i} {

                set index [lsearch -exact $QWIKMD::mutindex [lindex $QWIKMD::delete $i]]
                if {$index != -1} {
                    set QWIKMD::mutindex [lreplace $QWIKMD::mutindex $index $index]
                }

                set index [lsearch -exact $QWIKMD::protindex [lindex $QWIKMD::delete $i]]
                if {$index != -1} {
                    set QWIKMD::protindex [lreplace $QWIKMD::protindex $index $index]
                }

                set index [lsearch -exact $QWIKMD::renameindex [lindex $QWIKMD::delete $i]]
                if {$index != -1} {
                    set QWIKMD::renameindex [lreplace $QWIKMD::renameindex $index $index]
                }
            }
            puts $QWIKMD::textLogfile [QWIKMD::structPrepLog]
            puts $QWIKMD::textLogfile [QWIKMD::deleteLog]
        }
        
        cd $outputfoldername

        if {[file exists setup]!= 1} {
            file mkdir setup
        }

        if {[file exists run]!= 1} {
            file mkdir run
        }

        foreach par $QWIKMD::TopList {
            set f [open ${par} "r"]
            set out [open "setup/[file tail $par]" w+ ]
            set txt [read -nonewline ${f}]
            puts $out $txt
            close $f
            close $out
        }

        foreach par $QWIKMD::ParameterList {
            set f [open ${par} "r"]
            set out [open "run/[file tail $par]" w+ ]
            set txt [read -nonewline ${f}]
            puts $out $txt
            close $f
            close $out
        }
        if {$QWIKMD::basicGui(live,$tabid) == 1} {
            set QWIKMD::dcdfreq 1000
            #set QWIKMD::load 0
        } else {
            set QWIKMD::dcdfreq 10000
        }

        ## Save the original structure in the setup folder
        if {$QWIKMD::load == 0} {
            QWIKMD::getOriginalPdb setup
        } else {
            if {$QWIKMD::curframe > 0} {
                file copy -force $loadstartfile.xsc setup/
                file copy -force $loadstartfile.coor setup/[file tail ${prevoutputfolder}]_${QWIKMD::loadprotlist}_copy.restart.coor
                file copy -force $loadstartfile.vel setup/[file tail ${prevoutputfolder}]_${QWIKMD::loadprotlist}_copy.restart.vel

                file copy -force ${loadstartfile}.xsc run/[lindex [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 0] 0].xsc
                file copy -force ${loadstartfile}.vel run/[file tail ${prevoutputfolder}]_${QWIKMD::loadprotlist}_copy.restart.vel
            } else {
                set sel [atomselect top "all" frame now]
                $sel writepdb setup/[file tail ${prevoutputfolder}]_restart.pdb
                $sel delete
            }
            set psf ""
            catch {glob ${prevoutputfolder}/run/*.psf} psf
            set list {"nowater" "_noions" "_noh"}
            foreach str $list {
                set index [lsearch -regexp $psf (?i)$str]
                if {$index != -1} {
                    set psf [lreplace $psf $index $index]
                }
            }
            
            file copy -force ${psf} setup/
            
            ### Print restart from previous simulation information
            set name [file tail ${prevoutputfolder}]
            set prevInfoMD "${prevoutputfolder}/${name}.infoMD" 
            file copy -force ${prevInfoMD} setup/

            puts $QWIKMD::textLogfile $loadprevtext
            flush $QWIKMD::textLogfile
            
        }
        
        set step 0
        set prefix [file rootname [file tail $file] ]
        
        # Create NAMD input files, but not for MDFF protocol. MDFF protocol are created using MDFF Gui 
        if {$QWIKMD::run != "MDFF"} {
            if {$tabid == 0} {  
                set QWIKMD::confFile ""
                set text ""
                if {$QWIKMD::basicGui(prtcl,$QWIKMD::run,equi) == 1} {
                    lappend QWIKMD::confFile "qwikmd_equilibration_$step"
                    incr step
                }
                
                if {$QWIKMD::basicGui(prtcl,$QWIKMD::run,md) == 1} {
                    lappend QWIKMD::confFile "qwikmd_production_$step"
                    incr step
                }
                if {$QWIKMD::run == "SMD"} {
                    if {$QWIKMD::basicGui(prtcl,$QWIKMD::run,smd) == 1} {
                        lappend QWIKMD::confFile "qwikmd_production_smd_$step"
                        incr step
                    } 
                }
            } else {
                set QWIKMD::confFile [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 0]
            }
            set QWIKMD::prevconfFile $QWIKMD::confFile
        }
            
        set strct [QWIKMD::PrepareStructures $prefix $QWIKMD::textLogfile]
        ## Avoid prepare structures if preparing simulation from a loaded trajectory
        if {$QWIKMD::load == 0} {
            if {[string is integer [lindex $strct 0]] == 1} {
                tk_messageBox -message "Error during structure preparation: [lindex $strct 1]." -icon error \
                -parent $QWIKMD::topGui
                
                flush $QWIKMD::textLogfile
                close $QWIKMD::textLogfile
                return 1
            }

            if {[file exists "$env(QWIKMDTMPDIR)/Renumber_Residues.txt"] == 1} {
                set renfile [open "$env(QWIKMDTMPDIR)/Renumber_Residues.txt" r]
                set lines [read $renfile]
                close $renfile
                set lines [split $lines "\n"]
                puts $QWIKMD::textLogfile "\nRenumbering Residues Reference Table"
                foreach str $lines {
                    puts $QWIKMD::textLogfile $str
                }
                file copy -force "$env(QWIKMDTMPDIR)/Renumber_Residues.txt" ${QWIKMD::outPath}/setup/
            }
            puts $QWIKMD::textLogfile "[string repeat "=" 81]\n\n"
        }
        if {$QWIKMD::run == "QM/MM"} {
            # set ind 0
            # foreach prtcl [llength $QWIKMD::confFile] {
            #     if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$ind,qmmm) == 1} {
            #         if {$ind == 0} {
            set stfile [molinfo [molinfo top] get filename]
            set stctFile [lindex $stfile 0]  
            set filename [file root [file tail [lindex $stctFile 0] ] ]
            QWIKMD::PrepareQMMM [file root [lindex $strct 0]]
            #         }
            #         break
            #     }
            #     incr ind
            # } 
        }
        set QWIKMD::prepared 1
        if {$QWIKMD::run != "MDFF"} {
            if {$tabid == 0} {
                set QWIKMD::maxSteps [list]
            }
            for {set i 0} {$i < [llength $QWIKMD::confFile]} {incr i} {
                QWIKMD::NAMDGenerator $strct $i
            }
            puts $QWIKMD::textLogfile [QWIKMD::printMD]
        } else {
            set QWIKMD::prevconfFile "MDFF"
        }
        
        puts $QWIKMD::textLogfile "================================== MD Analysis ====================================\n\n"
        set list [molinfo list]
        cd $QWIKMD::outPath/run/
       

        set QWIKMD::inputstrct $strct

        set QWIKMD::nmrstep 0
        set input $QWIKMD::basicGui(workdir,0)
        QWIKMD::SaveInputFile $QWIKMD::basicGui(workdir,0)
        ## Change prepared variable to 0 to avoid the notification of killing the MD simulations
        set QWIKMD::prepared 0
        set logFile $QWIKMD::textLogfile
        QWIKMD::resetBtt 1
        set QWIKMD::basicGui(workdir,0) $input
        for {set i 0} {$i < $numtabs} {incr i} {
                if {$tabid != $i} {
                    $QWIKMD::topGui.nbinput tab $i -state normal
                }
            }
        source $input
        set tabid [$QWIKMD::topGui.nbinput index current]
        QWIKMD::mainTable [expr $tabid +1]
        QWIKMD::reviewTable [expr $tabid +1]
        QWIKMD::SelResid
        QWIKMD::ChangeSolvent
        
        ## QWIKMD::textLogfile is cleaned during reset
        set QWIKMD::textLogfile $logFile
        
        if {$tabid == 1 && $QWIKMD::run != "SMD"} {
            set sel [atomselect $QWIKMD::topMol "all"]
            $sel set beta 0
            $sel set occupancy 0
            $sel writepdb [lindex $strct 1]
            $sel delete
        }
        
        
        if {$QWIKMD::prepared == 1 && $QWIKMD::run != "MDFF"} {
            QWIKMD::defaultIMDbtt $tabid normal
            [lindex $QWIKMD::preparebtt $tabid] configure -state disabled
        }
        #$QWIKMD::runbtt configure -text "Start [QWIKMD::RunText]"
        set numframes [molinfo $QWIKMD::topMol get numframes]
        QWIKMD::updateTime load


        ttk::style configure WorkDir.TEntry -foreground black
        $QWIKMD::basicGui(workdir,1) configure -state disabled
        $QWIKMD::basicGui(workdir,2) configure -state disabled

        flush $QWIKMD::textLogfile
        close $QWIKMD::textLogfile
        QWIKMD::selectNotebooks 0
        QWIKMD::changeScheme
        QWIKMD::RenderChgResolution
        QWIKMD::lockGUI
        if {$QWIKMD::run == "MDFF"} {
            # set MDFF settings according to QwikMD parameters, working directory, and options chosen by the user
            QWIKMD::updateMDFF
        }
        if {[file exists $QWIKMD::basicGui(workdir,0)_temp] == 1} {
            catch {file delete -force -- $QWIKMD::basicGui(workdir,0)]_temp}
        }
        
        return 0
    } else {
        QWIKMD::saveBut prepare
        if {$QWIKMD::basicGui(workdir,0) != ""} {
            QWIKMD::PrepareBttProc $QWIKMD::basicGui(workdir,0)
        }
        
    }
}
# set MDFF settings according to QwikMD parameters, working directory, and options chosen by the user
proc QWIKMD::updateMDFF {} {

    QWIKMD::selectProcs
    update idletasks
    if {$QWIKMD::numProcs == "Cancel"} {
        return
    }
    
    tk_messageBox -message "You will be redirected to MDFF GUI plug-in where you can prepare and preform MDFF simulations."\
     -icon info -type ok -parent $QWIKMD::topGui
    MDFFGUI::gui::mdffgui           
    set MDFFGUI::settings::MolID $QWIKMD::topMol
    if {[info exists MDFFGUI::settings::QwikMDLogFile] == 1} {
        set MDFFGUI::settings::QwikMDLogFile "${QWIKMD::outPath}/[file tail ${QWIKMD::outPath}].infoMD"
    }
    set ::MDFFGUI::settings::FixedPDBSelText "[$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget 0,0 -text]"
    if {[$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget 0,1 -text] != "none"} {
        set ::MDFFGUI::settings::SSRestraints 1
    } else {
        set ::MDFFGUI::settings::SSRestraints 0
    }
    if {[$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget 0,2 -text] != "none"} {
        set ::MDFFGUI::settings::ChiralityRestraints 1
    } else {
        set ::MDFFGUI::settings::ChiralityRestraints 0
    }
    if {[$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget 0,3 -text] != "none"} {
        set ::MDFFGUI::settings::CispeptideRestraints 1
    } else {
        set ::MDFFGUI::settings::CispeptideRestraints 0
    }
    set MDFFGUI::settings::SimulationName $QWIKMD::prevconfFile
    set plist [list]
    foreach par $QWIKMD::ParameterList {
        lappend plist "$QWIKMD::outPath/run/[file tail $par]"
    }
    set MDFFGUI::settings::ParameterList $plist
    set ::MDFFGUI::settings::Temperature [expr $QWIKMD::basicGui(temperature,$QWIKMD::run,0) + 273]
    set ::MDFFGUI::settings::FTemperature [expr $QWIKMD::basicGui(temperature,$QWIKMD::run,0) + 273]
    set ::MDFFGUI::settings::Minsteps $QWIKMD::advGui(mdff,min)
    set ::MDFFGUI::settings::Numsteps $QWIKMD::advGui(mdff,mdff)
    switch $QWIKMD::advGui(solvent,$QWIKMD::run,0) {
        Vacuum {
            set MDFFGUI::settings::PBCorGBIS ""
        }
        Implicit {
            set MDFFGUI::settings::PBCorGBIS "-gbis"
        }
        Explicit {
            set MDFFGUI::settings::PBCorGBIS "-pbc"
        }

    }
    set tabid [$QWIKMD::topGui.nbinput index current]
    if {$QWIKMD::basicGui(live,$tabid) == 1} {
        set ::MDFFGUI::settings::IMD 1
        set ::MDFFGUI::settings::IMDWait 1
        set MDFFGUI::settings::IMDProcs $QWIKMD::numProcs
    }
    set MDFFGUI::settings::CurrentDir $QWIKMD::outPath/run/
    $QWIKMD::topGui.nbinput.f2.fcontrol.fcolapse.f1.imd.button_Pause configure -state disabled
    $QWIKMD::topGui.nbinput.f2.fcontrol.fcolapse.f1.imd.button_Finish configure -state disabled
    $QWIKMD::topGui.nbinput.f2.fcontrol.fcolapse.f1.imd.button_Detach configure -state disabled
    wm iconify $QWIKMD::topGui
}

## store the tabs select in the run tabs
## if opt is 0, redefine the variable, otherwise just select the tabs
proc QWIKMD::selectNotebooks {opt} {
    if {$opt == 0} {
        set tabid [expr [$QWIKMD::topGui.nbinput index current] +1]
        set QWIKMD::selnotbooks [list]
        lappend QWIKMD::selnotbooks [list $QWIKMD::topGui.nbinput [$QWIKMD::topGui.nbinput index current]]
        lappend QWIKMD::selnotbooks [list $QWIKMD::topGui.nbinput.f${tabid}.nb [$QWIKMD::topGui.nbinput.f${tabid}.nb index current]]
    } 

    foreach note $QWIKMD::selnotbooks {
        [lindex $note 0] select [lindex $note 1]
    }
}

proc QWIKMD::lockGUI {} {
    set tabid [$QWIKMD::topGui.nbinput index current]
         
    # set level basic
    # if {$tabid == 1} {
    #     set level advanced
    # }
    #### Set the variables to same values among the all tabs

    set prtcltabs {MD SMD}
    set solvent ""
    set saltions ""
    set saltconc ""
    if {$tabid == 0} {
        set solvent $QWIKMD::basicGui(solvent,$QWIKMD::run,0)
        set saltions $QWIKMD::basicGui(saltions,$QWIKMD::run,0)
        set saltconc $QWIKMD::basicGui(saltconc,$QWIKMD::run,0)
    } else {
        set solvent $QWIKMD::advGui(solvent,$QWIKMD::run,0)
        set saltions $QWIKMD::advGui(saltions,$QWIKMD::run,0)
        set saltconc $QWIKMD::advGui(saltconc,$QWIKMD::run,0)
    }
    set curprtcl [lindex [lindex $QWIKMD::selnotbooks 1] 1]
    set prtclnotebook [lindex $QWIKMD::notebooks 1]
    set runnotebook [lindex $QWIKMD::notebooks 0]
    # if {$tabid == 0} {
    set tabaux 0 
    $runnotebook select 0
    foreach prtcl $prtcltabs {

        $prtclnotebook select $tabaux
        $QWIKMD::basicGui(solvent,$prtcl) configure -state disabled
        $QWIKMD::basicGui(saltions,$prtcl) configure -state disabled
        $QWIKMD::basicGui(saltconc,$prtcl) configure -state disabled
        $QWIKMD::basicGui(prtcl,$prtcl,mdbtt) configure -state disabled
        $QWIKMD::basicGui(prtcl,$prtcl,equibtt) configure -state disabled
        $QWIKMD::basicGui(prtcl,$prtcl,mdtime) configure -state disabled
        $QWIKMD::basicGui(prtcl,$prtcl,mdtemp) configure -state disabled
        if {$prtcl == "SMD"} {
            $QWIKMD::basicGui(prtcl,$prtcl,smdbtt) configure -state disabled
            $QWIKMD::basicGui(prtcl,$prtcl,smdlength) configure -state disabled
            $QWIKMD::basicGui(prtcl,$prtcl,smdvel) configure -state disabled
        }
        
        if {$tabid == 0 && $tabaux == $curprtcl} {incr tabaux;continue}
        
        set solventaux $solvent
        if {$solvent == "Vacuum"} {
            set solvent "Implicit"
        }
        set QWIKMD::basicGui(solvent,$prtcl,0) $solvent
        set QWIKMD::basicGui(saltions,$prtcl,0) $saltions
        set QWIKMD::basicGui(saltconc,$prtcl,0) $saltconc
        set solvent $solventaux
        set state disabled
        if {[lindex [lindex $QWIKMD::selnotbooks 0] 1] == 0 && $tabaux == $curprtcl} {
            set state normal
        } elseif {$prtcl != "SMD" } {
            set state normal
        }
        $prtclnotebook tab $tabaux -state $state
        incr tabaux   
    }

    set prtcltabs [concat $prtcltabs {"MDFF" "QM/MM"}]
    set tabaux 0
    set prtclnotebook [lindex $QWIKMD::notebooks 2]
    
    set tabaux 0 
    $runnotebook select 1
    foreach prtcl $prtcltabs {
        $prtclnotebook select $tabaux
        $QWIKMD::advGui(solvent,$prtcl) configure -state disabled
        $QWIKMD::advGui(solvent,minbox,$prtcl) configure -state disabled   
        $QWIKMD::advGui(saltions,$prtcl) configure -state disabled
        $QWIKMD::advGui(saltconc,$prtcl) configure -state disabled
        $QWIKMD::advGui(solvent,boxbuffer,$prtcl,entry) configure -state disabled
        
        if {$tabid == 1 && $tabaux == $curprtcl} {
            if {$prtcl == "QM/MM"} {
                $QWIKMD::advGui(qmoptions,soft,cmb) configure -state disabled
                $QWIKMD::advGui(qmoptions,stpathbtt) configure -state disabled
                $QWIKMD::advGui(qmoptions,lssmode,cmb) configure -state disabled
                $QWIKMD::advGui(qmoptions,ptcharge,cmb) configure -state disabled
                $QWIKMD::advGui(qmoptions,cmptcharge,cmb) configure -state disabled
                $QWIKMD::advGui(qmoptions,switchtype,cmb) configure -state disabled
                $QWIKMD::advGui(qmoptions,ptchrgschm,cmb) configure -state disabled
                $QWIKMD::advGui(qmoptions,ptcqmwdgt) configure -state disabled
                set numcols [$QWIKMD::advGui(qmtable) columncount]
                for {set i 0} {$i < $numcols} {incr i} {$QWIKMD::advGui(qmtable) columnconfigure $i -editable false}
            } elseif {$prtcl == "SMD"} {
                $QWIKMD::advGui(prtcl,$prtcl,smdlength) configure -state disabled
                $QWIKMD::advGui(prtcl,$prtcl,smdvel) configure -state disabled
            }
            incr tabaux
            continue
        }

        set QWIKMD::advGui(solvent,$prtcl,0) $solvent
        set QWIKMD::advGui(saltions,$prtcl,0) $saltions
        set QWIKMD::advGui(saltconc,$prtcl,0) $saltconc
        set QWIKMD::advGui(solvent,boxbuffer,$prtcl) $QWIKMD::advGui(solvent,boxbuffer,$QWIKMD::run)
        set QWIKMD::advGui(solvent,minimalbox,$prtcl) $QWIKMD::advGui(solvent,minimalbox,$QWIKMD::run)
        set state disabled
        if {[lindex [lindex $QWIKMD::selnotbooks 0] 1] == 1 && $tabaux == $curprtcl} {
            set state normal
        } elseif {$prtcl != "SMD" && $prtcl != "MDFF"} {
            set state normal
        }
        $prtclnotebook tab $tabaux -state $state
        
        incr tabaux
    }
    $prtclnotebook select 0
    foreach notetab $QWIKMD::selnotbooks {
        [lindex $notetab 0] select [lindex $notetab 1]
    } 
    # } else {
    #     foreach prtcl $prtcltabs {
    #         set QWIKMD::advGui(solvent,$prtcl,0) $QWIKMD::advGui(solvent,$QWIKMD::run,0)
    #         set QWIKMD::advGui(saltions,$prtcl,0) $QWIKMD::advGui(saltions,$QWIKMD::run,0)
    #         set QWIKMD::advGui(saltconc,$prtcl,0) $QWIKMD::advGui(saltconc,$QWIKMD::run,0)
    #     }
    # }
    
    # if {$level == "basic"} {
    #     $QWIKMD::basicGui(solvent,$QWIKMD::run) configure -state disabled
    #     $QWIKMD::basicGui(saltions,$QWIKMD::run) configure -state disabled
    #     $QWIKMD::basicGui(saltconc,$QWIKMD::run) configure -state disabled
    #     $QWIKMD::basicGui(prtcl,$QWIKMD::run,mdbtt) configure -state disabled
    #     $QWIKMD::basicGui(prtcl,$QWIKMD::run,equibtt) configure -state disabled
    #     if {$QWIKMD::run == "SMD"} {
    #         $QWIKMD::basicGui(prtcl,$QWIKMD::run,smdbtt) configure -state disabled
    #     }
    #     # $QWIKMD::topGui.nbinput tab 1 -state disabled
    # } else {
    #     $QWIKMD::advGui(solvent,$QWIKMD::run) configure -state disabled
    #     $QWIKMD::advGui(solvent,minbox,$QWIKMD::run) configure -state disabled   
    #     $QWIKMD::advGui(saltions,$QWIKMD::run) configure -state disabled
    #     $QWIKMD::advGui(saltconc,$QWIKMD::run) configure -state disabled
    #     $QWIKMD::advGui(solvent,boxbuffer,$QWIKMD::run,entry) configure -state disabled
    #     # $QWIKMD::topGui.nbinput tab 0 -state disabled
    # }
    # foreach note [lrange $QWIKMD::notebooks 1 2] {
    #     $note state disabled
    # }
    set QWIKMD::tablemode "inspection"
    
    if {[winfo exists $QWIKMD::selResGui] == 1} {
        QWIKMD::tableModeProc
        QWIKMD::lockSelResid 0
    }
    [lindex $QWIKMD::livebtt $tabid] configure -state disabled
    $QWIKMD::advGui(ignoreforces,wdgt) configure -state disabled
    [lindex $QWIKMD::preparebtt $tabid] configure -state disabled
    [lindex $QWIKMD::autorenamebtt 0] configure -state disabled
    [lindex $QWIKMD::autorenamebtt 1] configure -state disabled
    #$QWIKMD::basicGui(live,$tabid) configure -state disabled
    #incr tabid
    #$QWIKMD::topGui.nbinput.f$tabid.fb.fcolapse.f1.preparereset.live configure -state disabled
    set state "disabled"
    if {$tabid == $curprtcl} {
        set state "normal"
    }
    for {set i 0} {$i < 2} {incr i} {
        [lindex $QWIKMD::nmrMenu $i] configure -state $state
        # [lindex $QWIKMD::chainMenu $i] configure -state disabled
    }
    
    set numcols [$QWIKMD::advGui(protocoltb,$QWIKMD::run) columncount]
    for {set i 0} {$i < $numcols} {incr i} {$QWIKMD::advGui(protocoltb,$QWIKMD::run) columnconfigure $i -editable false}
    $QWIKMD::topGui configure -cursor {}; update    
     
}

proc QWIKMD::addNAMDCheck {step} {
    set prefix [lindex $QWIKMD::confFile $step]
    set filename [lindex $QWIKMD::confFile $step]
    set namdfile [open ${QWIKMD::outPath}/run/${filename}.conf a]
    set file "[lindex $QWIKMD::confFile $step].check"

    puts $namdfile  "set file \[open ${file} w+\]"

    puts $namdfile "set done 1"
    set str $QWIKMD::run
    
    puts $namdfile "if \{\[file exists $prefix.restart.coor\] != 1 || \[file exists $prefix.restart.vel\] != 1 || \[file exists $prefix.restart.xsc\] != 1 \} \{"
    puts $namdfile "\t set done 0"
    puts $namdfile "\}"

    puts $namdfile "if \{\$done == 1\} \{"
    puts $namdfile "\tputs \$file \"DONE\"\n    flush \$file\n  close \$file"
    puts $namdfile "\} else \{"
    puts $namdfile "\tputs \$file \"One or more files failed to be written\"\n   flush \$file\n  close \$file"
    puts $namdfile "\}"
    close $namdfile

}

# proc QWIKMD::addConstOccup {conf input output pdb start midle end} {

#     set line ""
#     if {$output == "SMD_Index.pdb" && $input == "SMD_anchorIndex.txt"} {
#         append line "set do 0\n"
#         append line "if \{\[file exists $output \] == 0\} \{\n"
#     } elseif {$output == "SMD_Index.pdb" && $input == "SMD_pullingIndex.txt"} {
#         append line "if \{\$do == 1\} \{\n"
#     }
    
#     append line "\tset pdb $pdb\n"
#     append line "\tset file \[open \$pdb r\]\n"
#     append line "\tset line \[read -nonewline \$file\]\n"
#     append line "\tset line \[split \$line \"\\n\"\]\n"
#     append line "\tclose \$file\n"
#     append line "\tset out \[open $output w+\]\n"
#     append line "\tset indexfile \[open $input r\]\n"
#     append line "\tset vmdindexes \[read -nonewline \$indexfile\]\n"
#     append line "\tclose \$indexfile\n"
#     append line "\tforeach ind \$vmdindexes \{\n"
#     append line "\t\tset index \[lsearch -index 1 \[lrange \$line 0 \[expr \[\llength \$line\] -1\] \] \$ind\]\n"
#     append line "\t\tif \{\$index > -1\} \{\n"
#     append line "\t\t\tset lineauxformat \"\"\n"
#     append line "\t\t\tset lineauxformat \[string range \[lindex \$line \$index\] $start $midle\]\n"
#     append line "\t\t\tappend lineauxformat \[format  %+*s 6 1.00\]\n"
#     append line "\t\t\tappend lineauxformat \[string range \[lindex \$line \$index\] $end end\]\n"
#     append line "\t\t\tlset line \$index \$lineauxformat\n"
#     append line "\t\t\}\n"
#     append line "\t\}\n"
#     append line "\tfor \{set i 0\} \{\$i < \[llength \$line\]\} \{incr i\} \{\n"
#     append line "\t\tputs \$out \[lindex \$line \$i\]\n"
#     append line "\t\}\n"
#     append line "\tclose \$out\n"
#     if {$output == "SMD_Index.pdb"} {
#         append line "\tset do 1"
#         append line "\}\n"
#     }
#     set file [open $conf r]
#     append line [read $file]
#     close $file
#     set file [open $conf w+]
#     puts $file $line
#     close $file
# }


proc QWIKMD::addFirstTimeStep {step} {

    set line ""

    append line "set xsc [lindex $QWIKMD::confFile [expr $step -1]].xsc\n"
    append line "if \{\[file exists \$xsc\] == 0\} \{set xsc [lindex $QWIKMD::confFile [expr $step -1]].restart.xsc\}\n"
    append line "set file \[open \$xsc r\]\n"
    append line "set line \[read -nonewline \$file\]\n"
    append line "set line \[split \$line \"\\n\"\]\n"
    append line "close \$file\n"
    append line "firstTimeStep \[lindex \[lindex \$line 2\] 0\]"
    
    return $line
}


proc QWIKMD::infoWindow {name text title} {
    
    set wname ".$name"
    if {[winfo exists $wname] != 1} {
        toplevel $wname
    } else {
        wm deiconify $wname
        return
    }
    wm geometry $wname 600x400
    grid columnconfigure $wname 0 -weight 2
    grid rowconfigure $wname 0 -weight 2
    ## Title of the windows
    wm title $wname $title ;# titulo da pagina

    grid [ttk::frame $wname.txtframe] -row 0 -column 0 -sticky nsew
    grid columnconfigure  $wname.txtframe 0 -weight 1
    grid rowconfigure $wname.txtframe 0 -weight 1

    grid [text $wname.txtframe.info -wrap word -width 420 -bg white -yscrollcommand [list $wname.txtframe.scr1 set] -xscrollcommand [list $wname.txtframe.scr2 set] -exportselection true] -row 0 -column 0 -sticky nsew -padx 2 -pady 2
    
    
    for {set i 0} {$i <= [llength $text]} {incr i} {
        set txt [lindex [lindex $text $i] 0]
        set font [lindex [lindex $text $i] 1]
        $wname.txtframe.info insert end $txt
        set ini [$wname.txtframe.info search -exact $txt 1.0 end]
        
        set line [split $ini "."]
        set fini [expr [lindex $line 1] + [string length $txt] ]
         
        $wname.txtframe.info tag add $wname$i $ini [lindex $line 0].$fini
        if {$font == "title"} {
            set fontarg "helvetica 15 bold"
        } elseif {$font == "subtitle"} {
            set fontarg "helvetica 12 bold"
        } else {
            set fontarg "helvetica 12"
        } 
        $wname.txtframe.info tag configure $wname$i -font $fontarg
    }


        ##Scrool_BAr V
    scrollbar $wname.txtframe.scr1  -orient vertical -command [list $wname.txtframe.info yview]
    grid $wname.txtframe.scr1  -row 0 -column 1  -sticky ens

    ## Scrool_Bar H
    scrollbar $wname.txtframe.scr2  -orient horizontal -command [list $wname.txtframe.info xview]
    grid $wname.txtframe.scr2 -row 1 -column 0 -sticky swe

    grid [ttk::frame $wname.linkframe] -row 1 -column 0 -sticky ew -pady 2 -padx 2
    grid columnconfigure $wname.linkframe 0 -weight 2
    grid rowconfigure $wname.linkframe 0 -weight 2

    grid [tk::text $wname.linkframe.text -bg [ttk::style lookup $wname.linkframe -background ] -width 100 -height 1 -relief flat -exportselection yes -foreground blue] -row 1 -column 0 -sticky w
    $wname.linkframe.text configure -cursor hand1
    $wname.linkframe.text see [expr [string length $QWIKMD::link] * 1.0 -1]
    $wname.linkframe.text tag add link 1.0 [expr [string length $QWIKMD::link] * 1.0 -1]
    $wname.linkframe.text insert 1.0 $QWIKMD::link link
    $wname.linkframe.text tag bind link <Button-1> {
         if {$tcl_platform(platform) eq "windows"} {
                set command [list {*}[auto_execok start] {}]
                set url [string map {& ^&} $url]
            } elseif {$tcl_platform(os) eq "Darwin"} {
                set command [list open]
            } else {
                set command [list xdg-open]
            }
            exec {*}$command $QWIKMD::link &
      
      }
      bind link <Button-1> <Enter>
      $wname.linkframe.text tag configure link -foreground blue -underline true
      $wname.linkframe.text configure -state disabled

     
     $wname.txtframe.info configure -state disabled
}

proc QWIKMD::getrepnum {repname} {
    return [mol repindex $QWIKMD::topMol $repname]
}
proc QWIKMD::changeBCK {} {
    if {$QWIKMD::basicGui(desktop) == "white"} {
        color Display FPS black 
        color Axes Labels black 
    } elseif {$QWIKMD::basicGui(desktop) != ""} {
        color Display FPS white 
        color Axes Labels white 
    }
    if {$QWIKMD::basicGui(desktop) == "gradient"} {
        display backgroundgradient on
        color Display Background black
    } elseif {$QWIKMD::basicGui(desktop) != ""} {
        display backgroundgradient off
        color Display Background $QWIKMD::basicGui(desktop)
    }
}
proc QWIKMD::balloon {w help} {
    bind $w <Any-Enter> "after 5000 [list QWIKMD::balloon:show %W [list $help]]"
    bind $w <Any-Leave> "destroy %W.balloon"
}
  
proc QWIKMD::balloon:show {w arg} {
    if {[eval winfo containing  [winfo pointerxy .]]!=$w} {return}
    set top $w.balloon
    catch {destroy $top}
    toplevel $top -bd 1 -bg black
    wm overrideredirect $top 1
    if {[string equal [tk windowingsystem] aqua]}  {
        ::tk::unsupported::MacWindowStyle style $top help none
    }   
    pack [message $top.txt -aspect 10000 -bg lightyellow \
            -font fixed -text $arg]
    set wmx [winfo rootx $w]
    set wmy [expr [winfo rooty $w]+[winfo height $w]]
    wm geometry $top \
      [winfo reqwidth $top.txt]x[winfo reqheight $top.txt]+$wmx+$wmy
    raise $top
}

proc QWIKMD::tableballoon:show {tbl} {
    set w [$tbl labeltag]
    set col [tablelist::getTablelistColumn %W]
    set help 0
    
    switch $col {
        0 {
            set help [QWIKMD::selTabelChainBL]
        }
        1 {
            set help [QWIKMD::selTabelResidBL]
        }
        2 {
            set help [QWIKMD::selTabelTypeBL]
        }
        3 {
            set help [QWIKMD::selTabelRepBL]
        }
        4 {
            set help [QWIKMD::selTabelColorBL]
        }
        default {
            set help $col
        }
    }
    bind $w <Any-Enter> "after 5000 [list QWIKMD::balloon:show %W [list $help]]"
    bind $w <Any-Leave> "destroy %W.balloon"
}

proc QWIKMD::createInfoButton {frame row column} {
    image create photo QWIKMD::logo -data [QWIKMD::infoImage]
    grid [ttk::label $frame.info -image QWIKMD::logo -anchor center -background $QWIKMD::bgcolor] -row $row -column $column -sticky e -padx 0 -pady 0

    $frame.info configure -cursor hand1
}

proc QWIKMD::lockUnlockProc {index} {
    if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,lock) == 0} {
        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,lock) 1
        set state 0
        set color grey
    } else {
        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,lock) 0
        set state 1
        set color black
    }
    set numcols {0 1 3 4 5}
    for {set i 0} {$i < [llength $numcols]} {incr i} {

        $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $index,[lindex $numcols $i] -editable $state  
        $QWIKMD::advGui(protocoltb,$QWIKMD::run) cellconfigure $index,[lindex $numcols $i] -foreground $color -selectforeground $color  
    }
}

proc QWIKMD::checkProc {line} {
    set QWIKMD::confFile [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 0]
    set QWIKMD::maxSteps [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 1]

    set values {Minimization Annealing Equilibration MD SMD QMMM-Min QMMM-Ann QMMM-Equi QMMM}
    set row $line
    set current [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $row,0 -text]
    set index [lsearch $values $current]
    if {$index == -1} {
        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$row,lock) 0
        
    } else {
        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$row,lock) 1
        
    }
    QWIKMD::lockUnlockProc $row
}
##### Base64 string code for the info button logo. The original image is a GIF image and the decoded to base64.
##### If the original image is a png it will not work in linux (tested in a Centos 6.5)
proc QWIKMD::infoImage {} {
    set image {R0lGODlhFAAUAOefADVLnDdNnThOnjlPnjxSoD5UoUJXo0FYpENYo0RbpkZdp0tjq01jqlFkqlBorlRnrVdsr\
        1VtsVhtsFlws1pxtFxxslxys1pztV91tV92tl94uGF6uWV+vGZ/vWiAvGmBvmqDv3GEvW6GwG+IwnuKv3uKwHeMwnSOxn\
        mOxICPwniRyH6QxIGQw4CRxHmTyYaVxX6YzICYy4CZzIGazYKbzoObzYWbzIWczYqcy4Oe0I+cyYef0JGgzIij04qj04+i\
        z5Gjz5aizI6k0pOl0Y2p14+r2JCs2ZWr1ZGs2ZSs15iv2J+u1aCu1Z6v1pqw2Z+w1pyy2pqz3KCy2J6z2qex1Zu03Kmy1a\
        K23KS22q+52au83ra/3LbB3rbC4LjC3rnD4LvF4LzH4sHI4b/M5cDO6MHQ6MbQ58bS6s7U6MvV6c7W6s/W6c7Y69PY6tbb7\
        Njc7Njd7dje7tne7dXf79jf79rf7d3i797i8Nzj8d3k8d7k8eHk8N/m8+Lo8+Pp9OXp8+nu9+zu9e3v9u7x+O/x+O7y+PDy+\
        PHz+PL0+fL1+vT1+fT2+vX3+/b3+/b4+/f4+/j5+/j5/Pj6/Pn6/Pr6/Pn7/fr7/Pv7/fv8/fz8/fz8/vz9/v39/v3+/v7+/v\
        //////////////////////////////////////////////////////////////////////////////////////////////////\
        //////////////////////////////////////////////////////////////////////////////////////////////////\
        ////////////////////////////////////////////////////////////////////////////////////////////////\
        ///////////////////////////////////////////////////////////////////////////////////////////////y\
        H+EUNyZWF0ZWQgd2l0aCBHSU1QACH5BAEKAP8ALAAAAAAUABQAAAj+AI0IHEiwYEEiCBMmLBKlChKFCXtInNijDCBNkiZdqk\
        SGYo8cIHP4UOIJE58rSaBMOcNojpOQMGLCoOEJz4yYRwp50rLDUx+ZLoLWWORHSFAXYzh5khE0EZagJ6LqWXQjalQVdKTEiM\
        omT9QRI2wwMgMWbJpLiDiVfTIJLAgQahw1eQuCkacwmRD9eDvE01sOHAYxEgF4CacOXTxF+gAYyCbAGjRwsrQhMgoPGiZ5ih\
        NZwxdCkS9c8ORJtGkTiBzhMI2JiegIEQQ9ogAbNhhPjybA5oIpA2wHDrwY4gEceCdPaICv8LSm+IIFIf7Yeb7AQqNJLRZg8H\
        SH+gIF4LNWPGIhQcGLRofckG4DoQJ4BQfiJ9DxaEv8Ops8NSrBAI6c+AcQIKCADxziyR46pEBCEIFAIgYCBQgYwIQUGmDFG5\
        5QQokiVDRA4YQAhCjiiAMIMOKIAQEAOw==}
return $image
}



