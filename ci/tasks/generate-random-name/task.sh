#!/bin/bash
set -eu

adjective_list="abnormal addictive adventurous ambitious analytical annoying approachable
    beatable belated biweekly blathering blind bloodcurdling bottled breathable checkered
    cherished clever clinical closed cobwebby colossal combative combustible comforting
    condescending confident considerate consoling corpselike crabby crackling cranky credible
    creepy desecrating disreputable enthusiastic exasperating exceptionable horrendous
    hypercritical impossible impractical indiscreet inexperienced manipulative objectionable
    respectful sophisticated straightforward superstitious unimaginative vulnerable warmhearted wingdang"

noun_list="anaconda antelope baloney banjo bathrobe bathtub belief brainchild bunny carver
    charger chicken clouds cookie corpse crafter crocodile crusher demon dinosaurs exorcism fangs
    farmer flower foobrizzle haunting hotdog hunter jellybean kicker knowledge lasagna lizard lumberjack
    manic memory mimicker mobster mouth oatmeal onionskin organization preacher pumpkin puppy
    quilt refrigerator roarer scorpion shaker shower sidewalk skulls snails snakes spacesuit
    spike squirrel suitcase sweatshirt sweatsuit swisher swordfish tiger trains turtle umbrella
    volleyball weaver worms"

adjectives=(${adjective_list})
num_adj=${#adjectives[*]}
nouns=(${noun_list})
num_nouns=${#nouns[*]}

chosen_adj=${adjectives[$((RANDOM % num_adj))]}
chosen_noun=${nouns[$((RANDOM % num_nouns))]}

new_env_name="${chosen_adj}-${chosen_noun}"
echo "Checking if ${new_env_name} exists..."
matching_envs=$(find pool-repo -type f -name ${new_env_name})

if [[ -n "${matching_envs}" ]]; then
    echo "${new_env_name} already exists. Aborting..."
    exit 1
fi

echo "${new_env_name}" > new-lock/name
touch new-lock/metadata
