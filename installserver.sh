#!/bin/bash
./linuxgsm.sh $GAMESERVER
yes | ./$GAMESERVER install
./$GAMESERVER start

