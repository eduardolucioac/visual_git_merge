#!/bin/bash

# NOTE: Evita problemas com caminhos relativos! By Questor
SCRIPTDIR_V="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $SCRIPTDIR_V/ez_i.bash

read -d '' INSTRUCT_F <<"EOF"
Makes the merge of a branch with the "master" branch - will OVERWRITING "master" branch - using a visual diff and merge tool (meld).

TIP: TO CANCEL this process at any time use Ctrl+c!
EOF

# NOTE: Mensagem de "commit" de merge do branch "master" com o branch "não master". By Questor
MASTER_TO_NOT_M='Merge do branch \"master\" no branch \"$NOT_MASTER_BRANCH\". By Questor'
NOT_M_TO_MASTER='Merge do branch \"$NOT_MASTER_BRANCH\" no branch \"master\". By Questor'

f_instruct "$INSTRUCT_F"
echo ""
f_enter_to_cont

# NOTE: Verifica se a pasta atual é um repositório git válido. By Questor
f_chk_for_repo() {
    f_chk_fd_fl ".git" "d"
    if [ ${CHK_FD_FL_R} -eq 0 ] ; then
        f_enter_to_cont "ERROR: The current directory is not a valid git repository!"
        f_error_exit
    fi
}

# NOTE: Verifica se o "meld" está presente. By Questor
f_chk_for_meld() {
    # https://stackoverflow.com/a/677212/3223785
    # https://askubuntu.com/a/445473/134723
    if ! [ -x "$(command -v meld)" ]; then
        f_enter_to_cont "ERROR: Meld visual diff and merge tool is not present!
( https://meldmerge.org/ )"
        f_error_exit
    fi
}

# NOTE: To debug. By Questor
# USR_CREDENTIALS="https://eduardolucioac:3M%40nu3773@gitlab.com/lbss/lbrad.git"

USR_CREDENT_FL=""
USR_CREDENTIALS=""
f_usr_credent_fl() {
    # https://stackoverflow.com/a/41555893/3223785
    USR_CREDENT_FL=$(mktemp -t tmp.XXXXXX)
    echo "$USR_CREDENTIALS" > "$USR_CREDENT_FL"
    trap "rm -f $USR_CREDENT_FL" EXIT HUP INT QUIT TERM STOP PWR
}

# NOTE: Obtêm usuário e senha do git para aumentar a automatização do processo. By Questor
f_get_usr_credent() {
    f_div_section
    echo "Inform git user and password:"

    f_get_usr_input "git user"
    f_ez_sed "@" "%40" "" 0 0 1 0 -1 "$GET_USR_INPUT_R"
    GIT_USER_NAME=$F_EZ_SED_R

    f_get_usr_input "git password" 0 1
    f_ez_sed "@" "%40" "" 0 0 1 0 -1 "$GET_USR_INPUT_R"
    GIT_USER_PWD=$F_EZ_SED_R

    f_split "$(git remote get-url origin)" "://"
    USR_CREDENTIALS="${F_SPLIT_R[0]}://$GIT_USER_NAME:$GIT_USER_PWD@${F_SPLIT_R[1]}"

    # https://stackoverflow.com/q/4089430/3223785
    # https://stackoverflow.com/q/4089430/3223785
    # https://stackoverflow.com/a/52879494/3223785
    # https://stackoverflow.com/a/22957485/3223785

    f_usr_credent_fl

}

f_repo_backup() {
    BACKUP_OP=$1

    if [ ${BACKUP_OP} -eq 1 ] ; then

        # NOTE: Backup do repositório atual. By Questor
        # https://stackoverflow.com/a/34119867/3223785
        f_ez_mv_bak "$(pwd)" "Back up the current repository? (\"y\" recommended)" 0 1

    else
        if [ ${F_BAK_MD_R} -eq 1 ] ; then
        # NOTE: Remover backup do repositório atual. By Questor

            f_yes_no "Remove backup from current repository?"
            if [ ${YES_NO_R} -eq 1 ] ; then
                rm -rf "$F_BAK_PATH_R"
            fi
        fi
    fi
}

f_git_pull_changes() {
    BRANCH_NAME=$1
    f_div_section
    f_yes_no "Pull (\"$BRANCH_NAME\") branch?"
    if [ ${YES_NO_R} -eq 1 ] ; then

        # NOTE: Executa o comando "pull", ou seja, atualiza e faz merge com o repositório. 
        # By Questor
        f_get_stderr_stdout "git -c credential.helper=\"store --file=$USR_CREDENT_FL\" pull origin $BRANCH_NAME"
        if [[ $F_GET_STOUTERR == *"fatal: "* ]] || [[ $F_GET_STOUTERR == *"error: "* ]] ; then
            f_enter_to_cont "$F_GET_STOUTERR"
            f_error_exit
        fi
        echo "$F_GET_STOUTERR"

    fi
}

f_git_push_changes() {
    BRANCH_NAME=$1
    f_div_section
    f_yes_no "Push (\"$BRANCH_NAME\") branch?"
    if [ ${YES_NO_R} -eq 1 ] ; then

        # NOTE: Executa o comando "push", ou seja, envia modificações "commitadas" 
        # para o repositório. By Questor
        f_get_stderr_stdout "git -c credential.helper=\"store --file=$USR_CREDENT_FL\" push origin $BRANCH_NAME"
        if [[ $F_GET_STOUTERR == *"fatal: "* ]] || [[ $F_GET_STOUTERR == *"error: "* ]] ; then
            f_enter_to_cont "$F_GET_STOUTERR"
            f_error_exit
        fi
        echo "$F_GET_STOUTERR"

    fi
}

f_repo_fecth_all() {
    f_get_stderr_stdout "git -c credential.helper=\"store --file=$USR_CREDENT_FL\" fetch --all"
    if [[ $F_GET_STOUTERR == *"fatal: "* ]] || [[ $F_GET_STOUTERR == *"error: "* ]] ; then
        f_enter_to_cont "$F_GET_STOUTERR"
        f_error_exit
    fi
    echo "$F_GET_STOUTERR"
}

f_handle_master() {

    # https://unix.stackexchange.com/a/155077/61742
    f_div_section
    echo "Checkout to master"
    f_get_stderr_stdout "git checkout master"
    if [[ $F_GET_STOUTERR == *"fatal: "* ]] || [[ $F_GET_STOUTERR == *"error: "* ]] ; then
        f_enter_to_cont "$F_GET_STOUTERR"
        f_error_exit
    fi
    echo "$F_GET_STOUTERR"
    if [ -n "$(git status --porcelain)" ] ; then
        f_div_section
        f_yes_no "There are modifications on \"master\" branch!
Handle these modifications?"
        if [ ${YES_NO_R} -eq 1 ] ; then

            # NOTE: Faz uma cópia do repositório atual para iniciar o processo de merge. By Questor
            # cp -avr "$(pwd)" "$(pwd)_ours_master"
            cp -ar "$(pwd)" "$(pwd)_ours_master"

            git reset --hard origin/master

            f_div_section
            echo "TIP: Your changes o branch \"master\" will be on the LEFT!
WARNING: CHANGES ON LEFT WILL BE IGNORED!"
            f_div_section

            meld "$(pwd)_ours_master" "$(pwd)" 2> /dev/null 1> /dev/null

            # NOTE: Remove a cópia do repositório no branch setado. By Questor
            rm -rf "$(pwd)_ours_master"

            f_div_section
            f_get_usr_input "Inform your commit message
(all changes will be added)"
            git add --all
            COMMIT_MSG=$GET_USR_INPUT_R
            f_get_stderr_stdout "git commit -a -m \"$COMMIT_MSG\""
            if [[ $F_GET_STOUTERR == *"fatal: "* ]] || [[ $F_GET_STOUTERR == *"error: "* ]] ; then
                f_enter_to_cont "$F_GET_STOUTERR"
                f_error_exit
            fi
            echo "$F_GET_STOUTERR"

            f_git_push_changes "master"

        else
            f_okay_exit "It is not possible to proceed without handling the modifications on \"master\" branch."
        fi
    else
        f_git_pull_changes "master"
    fi

}

BRANCHES_ARR=()
BRANCHES_OPT_ARR=()
f_branches_list() {

    # NOTE: To debug. By Questor
    # 8a07004ca840bc3128a7f4ddd762d0563f8247c1        HEAD
    # 6d9c3a26504b27a9d3a2c3fa510b03a7d924e4d7        refs/heads/issue#40
    # dd5aabff50aa7e7687aa4fbfc861b8b7654f44b1        refs/heads/issue#44
    # 44000306b3592cb0aee1b081913f8f401eb9ab27        refs/heads/issue#45
    # 2593240b14578a6f164fe3847bb28804d1d741ad        refs/heads/issue#46
    # 8a07004ca840bc3128a7f4ddd762d0563f8247c1        refs/heads/master
    # 4fb21c2f62b5fe7a157d621c30b4be6aafb715d6        refs/merge-requests/1/head

    f_get_stderr_stdout "git -c credential.helper=\"store --file=$USR_CREDENT_FL\" ls-remote"
    if [[ $F_GET_STOUTERR == *"fatal: "* ]] || [[ $F_GET_STOUTERR == *"error: "* ]] ; then
        f_enter_to_cont "$F_GET_STOUTERR"
        f_error_exit
    fi
    f_split "$F_GET_STDOUT_R" "\n"
    F_SPLIT_R_0=("${F_SPLIT_R[@]}")
    TOTAL_0=${#F_SPLIT_R_0[*]}
    f=0
    for (( i=0; i<=$(( $TOTAL_0 -1 )); i++ )) ; do
        if [[ "${F_SPLIT_R_0[$i]}" == *"refs/heads/"* ]] ; then
            f_split "${F_SPLIT_R_0[$i]}" "refs/heads/"
            BRANCHES_ARR+=("${F_SPLIT_R[1]}")
            # https://stackoverflow.com/a/1951523/3223785
            BRANCHES_OPT_ARR+=("$f")
            BRANCHES_OPT_ARR+=("${F_SPLIT_R[1]}")
            f=$[$f+1]
        fi
    done
}

NOT_MASTER_BRANCH=""
f_choose_not_master_branch() {
    f_branches_list
    f_div_section
    f_get_usr_input_mult "Choose the name of the branch that will be merged with the master branch.
WARNING: The master branch will be OVERWRITTEN with these changes!" BRANCHES_OPT_ARR[@]
    NOT_MASTER_BRANCH="$GET_USR_INPUT_MULT_V_R"
    if [[ -z $(git show-ref refs/heads/$NOT_MASTER_BRANCH) ]]; then

        # https://www.reddit.com/r/git/comments/8wshx0/cant_get_git_checkout_t_originfeature_to_work/e1y1iu3?utm_source=share&utm_medium=web2x
        f_div_section
        echo "Cretate $NOT_MASTER_BRANCH branch and checkout to it"
        f_get_stderr_stdout "git -c credential.helper=\"store --file=$USR_CREDENT_FL\" checkout -b $NOT_MASTER_BRANCH origin/$NOT_MASTER_BRANCH"
        if [[ $F_GET_STOUTERR == *"fatal: "* ]] || [[ $F_GET_STOUTERR == *"error: "* ]] ; then
            f_enter_to_cont "$F_GET_STOUTERR"
            f_error_exit
        fi
        echo "$F_GET_STOUTERR"

        f_git_pull_changes "$NOT_MASTER_BRANCH"

    else

        # https://stackoverflow.com/a/12538667/3223785
        UP_TO_TRACK_REMOTE=0
        f_split "$(git branch -vv)" "\n"
        F_SPLIT_R=("${F_SPLIT_R[@]}")
        TOTAL=${#F_SPLIT_R[*]}
        for (( i=0; i<=$(( $TOTAL -1 )); i++ )) ; do
            if [[ "${F_SPLIT_R[$i]}" == *" $NOT_MASTER_BRANCH "* ]] && [[ "${F_SPLIT_R[$i]}" == *" [origin/$NOT_MASTER_BRANCH] "* ]] ; then
                UP_TO_TRACK_REMOTE=1
                break
            fi
        done
        if [ ${UP_TO_TRACK_REMOTE} -eq 0 ] ; then
            f_enter_to_cont "ERROR: Branch \"$NOT_MASTER_BRANCH\" IS NOT set up to track remote branch \"$NOT_MASTER_BRANCH\" from \"origin\"."
            f_error_exit
        fi

        f_div_section
        echo "Checkout to $NOT_MASTER_BRANCH"
        f_get_stderr_stdout "git checkout $NOT_MASTER_BRANCH"
        if [[ $F_GET_STOUTERR == *"fatal: "* ]] || [[ $F_GET_STOUTERR == *"error: "* ]] ; then
            f_enter_to_cont "$F_GET_STOUTERR"
            f_error_exit
        fi
        echo "$F_GET_STOUTERR"

        f_git_pull_changes "$NOT_MASTER_BRANCH"

    fi
}

f_merge_master_n_not_master() {

    # NOTE: Faz uma cópia do repositório atual para iniciar o processo de merge. By Questor
    # cp -avr "$(pwd)" "$(pwd)_master"
    cp -ar "$(pwd)" "$(pwd)_master"

    # NOTE: Coloca o repositório de comparação no branch master. By Questor
    cd "$(pwd)_master"

    f_div_section
    echo "Checkout to master"
    f_get_stderr_stdout "git checkout master"
    if [[ $F_GET_STOUTERR == *"fatal: "* ]] || [[ $F_GET_STOUTERR == *"error: "* ]] ; then
        f_enter_to_cont "$F_GET_STOUTERR"
        f_error_exit
    fi
    echo "$F_GET_STOUTERR"

    cd -

    f_div_section
    echo "TIP: The branch \"$NOT_MASTER_BRANCH\" will be on the RIGHT and \"master\" on the LEFT!
WARNING: CHANGES ON LEFT WILL BE IGNORED!"
    f_div_section

    meld "$(pwd)_master" "$(pwd)" 2> /dev/null 1> /dev/null

    # NOTE: Remove a cópia do repositório no branch setado. By Questor
    rm -rf "$(pwd)_master"

    # NOTE: Merge do branch "não master" no branch "master". O branch "master" será 
    # sobreescrito. By Questor
    git merge -s ours master

    # TODO: Voltar a essa ordem? By Questor
    git add --all
    git commit -a -m "$(eval echo $MASTER_TO_NOT_M)"

    f_git_push_changes "$NOT_MASTER_BRANCH"

}

f_merge_not_master_n_master() {

    f_div_section
    echo "Checkout to master"
    f_get_stderr_stdout "git checkout master"
    if [[ $F_GET_STOUTERR == *"fatal: "* ]] || [[ $F_GET_STOUTERR == *"error: "* ]] ; then
        f_enter_to_cont "$F_GET_STOUTERR"
        f_error_exit
    fi
    echo "$F_GET_STOUTERR"

    f_div_section
    f_yes_no "Merge with master branch?"
    if [ ${YES_NO_R} -eq 1 ] ; then
        git merge $NOT_MASTER_BRANCH
    fi

}

f_delete_merged_not_master() {

    f_div_section
    f_yes_no "Delete merged (\"$NOT_MASTER_BRANCH\") branch (local and remote)?
NOTE: Additionally will delete multiple obsolete tracking branches."

    if [ ${YES_NO_R} -eq 1 ] ; then

        # NOTE: Deletar o branch local. By Questor
        # git branch -D $NOT_MASTER_BRANCH
        git branch -d $NOT_MASTER_BRANCH

        # NOTE: Deletar o branch remoto. By Questor
        f_get_stderr_stdout "git -c credential.helper=\"store --file=$USR_CREDENT_FL\" push origin --delete $NOT_MASTER_BRANCH"
        if [[ $F_GET_STOUTERR == *"fatal: "* ]] || [[ $F_GET_STOUTERR == *"error: "* ]] ; then
            f_enter_to_cont "$F_GET_STOUTERR"
            f_error_exit
        fi
        echo "$F_GET_STOUTERR"

        # NOTE: Delete multiple obsolete tracking branches. By Questor
        f_get_stderr_stdout "git -c credential.helper=\"store --file=$USR_CREDENT_FL\" fetch --all --prune"
        if [[ $F_GET_STOUTERR == *"fatal: "* ]] || [[ $F_GET_STOUTERR == *"error: "* ]] ; then
            f_enter_to_cont "$F_GET_STOUTERR"
            f_error_exit
        fi
        echo "$F_GET_STOUTERR"

    fi

}

# EXEC >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

f_chk_for_repo
f_chk_for_meld
f_get_usr_credent
f_repo_backup 1
f_repo_fecth_all

# >>>>> checkout "master"
f_handle_master

# >>>>> checkout "not_master"
f_choose_not_master_branch

f_merge_master_n_not_master

# >>>>> checkout "master"
f_merge_not_master_n_master

f_delete_merged_not_master

f_git_push_changes "master"

f_repo_backup 0

# EXEC <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

f_div_section
echo "Done! Thanks"
f_div_section

exit 0