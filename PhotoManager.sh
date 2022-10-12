#!/bin/bash


Help(){
	echo -e "\n\n\n\n${bold}NAME: \n${normal}PhotoManager \n${bold}DESCRIPTION: ${normal}\nthis is a script that helps you to manage a directory full of disordered pictures \n (${bold}NB${normal} file's extension must be: ${bold} jpg,jpeg,JPG,JPEG${normal})  \n the script must be launched like that: \n${bold}$0 [OPTION][SOURCE_PATH]${bold} \n\n${bold}OPTIONS: ${normal} \n\n${bold}\n-d ${normal}DataOrganizer: permit to organize pictures taken in the same day in a folder\n${bold} \n-s ${normal}SizeSorter: permit to manage the file sorted by size\n${bold}\n-f ${normal} LocationFinder: returns the location where each photo has been shot (Requires internet connection)\n${bold}\n-i ${normal} ImageVisualizer: let you see the images you're working on in the same gallery\n\n${bold}-h${normal} Display Help \n\n${bold}© sofaking${normal}  "
}


#check if the path passed it's ok and if the folder's content it's ok $1directorypath
PathCheck(){
				FILE_COUNTER="0"
				
				if [[ "$1" = "" ]]; then
				echo "${bold}Error: Path not found${normal}"
				exit 1;
				
				elif [[ ! -d "$1" ]]; then
				echo "${bold}Error: Wrong Path${normal}"
				exit 1;
				
				fi
				cd "$1"
				
				#the path is correct now we veirfy if the folder is empty

				FILE_COUNTER=$(find "$1" -maxdepth 1 -type f | wc -l) 
				
				((FILE_COUNTER=FILE_COUNTER-1))
				
				if [[ "$FILE_COUNTER" = "0" ]]; then
				echo "${bold}Error: No files${normal}"
				exit 1;
				fi
				
				#now we verify if all the fails have the admittet extensions
				for file in "$1"/*
				do
				if [[ ! -d "$file" ]]; then
					if [ "${file: -4}" != ".JPG" ] && [ "${file: -5}" != ".JPEG" ] && [ "${file: -4}" != ".jpg" ] && [ "${file: -5}" != ".jpeg" ]; then
						echo "${bold}Error: bad extension file ( ${bold} $file ${normal} ), please check admitted extensions in -help !${normal}"
   						exit 1;
					fi
				fi			
				done
				}
				
				
				
#open the gallery next to the terminal $1 pathname
ImageVisualizer(){
  	arrPics=($(ls "$1"))
  	open  "${arrPics[@]}"
	exit 0
}

#update the galler(if already opened) next to the terminal $1 pathname
UpdateVisualizer(){
	pkill -x Preview
  	arrPics=($(ls "$1"))
  	open  "${arrPics[@]}"
}

#ask if you want to see the gallery or not $1 is the path
AskForVisualizer(){
read -p "Do you want to visualize your gallery? [Y/N] " choice
			 if [[ "$choice" == "Y" ]]; then
			UpdateVisualizer "$1"
			 elif [ "$choice" != "N" ]; then
			echo "${bold}Invalid Answer${normal}"
			pkill -x Preview
			exit 1
			else 	
			pkill -x Preview
			fi
}

#used in the -s section, manage the deleting of the data $1selection,$2directorypath,$3deletedimages,$4visualizerchoice
Delete(){
	case "$1" in 
	0)
		exit 0;	
		;;
	ALL)
					
			if [[ ! -d "$3" ]]; then
			 mkdir "$3"
			fi
			for filename in $(ls -p "$2" | grep -v /)
			do
			mv $filename "$3"
			done
			if [[ "$4" = "1" ]]; then
			UpdateVisualizer "$2"
			fi
			echo -e "\n${bold}all pictures deleted${normal}\n "
			exit 0;
			;;
		*)
			 for filename in $(ls "$2")
			do
				if [[ "$1" == "$filename" ]]; then
					if [[ -d "$3" ]]; then
						mv "$1" "$3"
						DELETED="1"
					else
				 		mkdir "$3"
						mv "$1" "$3"
						DELETED="1"
				 	fi
				fi
 			done
 			
 			
			 if [[ "$DELETED" -eq "0" ]]; then
 			echo "${bold}Error: File not found${normal}"
 			else
 			if [[ "$4" = "1" ]]; then
			UpdateVisualizer "$2"
			fi
 			echo -e "\n$1 deleted\n "
 			fi
 			;;
	esac
}



bold=$(tput bold) #to bold output
normal=$(tput sgr0)
BLUE='\033[0;34m' #to blue output
RED='\033[0;31m'
NC='\033[0m'
DIRECTORY_PATH="" #inizialize directory path

while :
	do
		case "$1" in
			-h | -help)
							Help
							exit 0
							;;
			-f)
				shift 1
				DIRECTORY_PATH="$1"
				PathCheck "$1"
				AskForVisualizer "$1"
				cd $DIRECTORY_PATH
				echo -e "\n${bold}Images list:${normal}\n"
				 OUTPUT=$(ls -lhpS | grep -v / | awk '{print $9}')
				 echo -e "${BLUE}$OUTPUT${NC}\n"
				 read -p "Enter the filename of the picture you want to visualize on map " choice
				 for filename in $(ls $DIRECTORY_PATH)
				do
						if [[ "$choice" == "$filename" ]]; then
						lat=$(mdls $filename | grep Latitude | awk '{print $3}')
 						long=$(mdls $filename | grep Longitude | awk '{print $3}')
 						if [[ "$lat" = "" ]]; then
 						echo "${bold}Error: Position not found${normal}"
 						pkill -x Preview
 						exit 0
 						fi
 						open https://www.google.com/maps/@$lat,$long,20z #20z is the zoom on the area of the picture
 						pkill -x Preview
 						exit 0
 						fi
 				done
 				echo "${bold}Error: File not found${normal}"
 				pkill -x Preview
 				exit 2
  				;;
			-s)
			
			 shift 1
			DIRECTORY_PATH="$1"
			DELETEDIMAGES="deletedimages"
			FLAG="0"
			VISUALIZER="0"
			INITIAL_SIZE=$(ls -l "$1" | grep -v '^d' | awk '{size+=$5} END {print size/(1000000)}') #size without counting subfolders
			while [ "$FLAG" -eq "0" ] 
			do
			PathCheck "$1"
			cd $DIRECTORY_PATH
			read -p "Do you want to visualize your gallery? [Y/N] " choice
			 if [[ "$choice" == "Y" ]]; then
			UpdateVisualizer "$1"
			VISUALIZER="1"
			 elif [ "$choice" = "N" ]; then
			 pkill -x Preview
			 VISUALIZER="0"
			 else
			echo "${bold}Invalid Answer${normal}"
			 pkill -x Preview
			exit 1
			fi
			echo -e "\n${bold}Images list:${normal}\n"
			 OUTPUT=$(ls -lhpS | grep -v / | awk '{print $9,$5}')
			echo -e "${BLUE}$OUTPUT${NC}\n"			
			echo -e "${bold}Occupied Space:${normal}"
			ACTUAL_SIZE=$(ls -l | grep -v '^d' | awk '{size+=$5} END {print size/(1000000)}')
			echo -e "$ACTUAL_SIZE MB\n" 
			echo -e "was:"
			 echo -e "$INITIAL_SIZE MB \n"			
			read -p "Enter the filename of the file you want to delete, 0 to exit, ALL to delete all images: " selection
			 if [[ "$selection" == "ALL" ]]; then
			read -p "You really want to delete all the images? [Y/N] " choice
			 if [[ "$choice" == "N" ]]; then
			 pkill -x Preview
			exit 0;
			 elif [ "$choice" != "Y" ]; then
			echo "${bold}Invalid Answer${normal}"
			pkill -x Preview
			exit 1
			 fi
			 fi
			Delete "$selection" "$DIRECTORY_PATH" "$DELETEDIMAGES" "$VISUALIZER"
			read -p "You want to delete again? [Y/N] " choice
			 if [[ "$choice" == "N" ]]; then
			 FLAG="1"
			 exit 0;
			 elif [ "$choice" == "Y" ]; then
			 FLAG="0"
			 else 
			echo "${bold}Invalid Answer${normal}"
			pkill -x Preview
			exit 1
			fi

			done

			;;
			-d)
				
				DESTINATION_PATH=""
				CALENDAR="Calendar"
				DATA=""
				shift 1
				DIRECTORY_PATH="$1"
				PathCheck "$1"				
				cd $DIRECTORY_PATH
				DESTINATION_PATH="$DIRECTORY_PATH/$CALENDAR"
				 if [[ -d "$DESTINATION_PATH" ]]; then
				 cd $DESTINATION_PATH
				 else
				 mkdir $CALENDAR
				 cd $CALENDAR
				 fi
 				for file in "$DIRECTORY_PATH"/*
				do
					if [[ -f "$file" ]]; then
					DATA=$(mdls $file | grep ItemContentCreationDate | head -n 1 | awk '{print $3}')
					if [[ -d "$DATA" ]]; then
					cp $file "$DATA"
					else
					mkdir "$DATA"
					cp $file "$DATA"
					fi
					fi			
			done
			echo -e "\n${bold}Images reordered!${normal}\n"
			exit 0;				 	
			;;
			-i)
				 shift 1
				DIRECTORY_PATH="$1"
				PathCheck "$1"			
				cd $DIRECTORY_PATH
				ImageVisualizer "$DIRECTORY_PATH"
			;;
			-*)
			echo "${bold}Error: Unknown option${normal}: $1" >&2
			read -p "You need help? [Y/N] " choice
			 if [[ "$choice" == "Y" ]]; then
			 Help
			 else 
			 exit 2;
			 fi
			;;
			*)
				Help
				exit 2;
			;;
			esac
	done




