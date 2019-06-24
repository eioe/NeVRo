# coding=utf-8
"""
Write a random search bash file.

Author: Simon Hofmann | <[surname].[lastname][at]pm.me> | 2017, 2019 (Update)
"""

from load_data import *
import sys
import fileinput

# < o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >>
# Set paths to bashfile dir
p2_bash = './bashfiles/'

# If no bashfile dir: create it
if not os.path.exists(p2_bash):
    os.mkdir(p2_bash)
# < o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >>

# # # Adapt here for which subjects bashfiles should be written and in which condition

condi = "nomov"  # "mov"
if "condi" not in locals():
    condi = input("Write bash files for 'M'ov or 'N'oMov condition: ")
    condi = "nomov" if "n" in condi.lower() else "mov"
cprint(f"Condition is set to: {condi}", "b")

# < o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >>

n_sub = 45
all_subjects = np.linspace(start=1, stop=n_sub, num=n_sub, dtype=int)  # np.arange(1, n_sub+1)
# dropouts = np.array([1, 12, 32, 33, 38, 40, 45])
# These are additional dropouts for the nomov-condition (add_drop). Criterium: More than 1/3 of all epochs
# (1 epoch = 1 sec of EEG data) in the EEG-channel data were above 100 μV. This would lead to an
# calculation of unreliable ICA-weights, dominated by the noisy segments.
# add_drop = [10, 16, 19, 23, 41, 43]  # no mov
# dropouts = np.append(dropouts, add_drop)

# Load SSD selection table
ssd_comp_sel_tab = pd.read_csv(f"../../../Data/EEG/07_SSD/{condi}/SSD_selected_components_{condi}.csv",
                               sep=";")
# Remove Subjects without any selected component
dropouts = np.array(ssd_comp_sel_tab[pd.isna(ssd_comp_sel_tab['n_sel_comps'])]["# ID"])
# # Dropout Criterion can be set to treshold, e.g. here min 4 selected comps:
# dropouts = np.append(dropouts, np.array(ssd_comp_sel_tab[ssd_comp_sel_tab['n_sel_comps'] < 4]["# ID"]))

subjects = np.setdiff1d(all_subjects, dropouts)  # These are all subjects without dropouts

# Test
# subjects = [21, 37]

# # Broad random search on subset of 10 subjects
subsubjects = np.random.choice(a=subjects, size=10, replace=False)

# # Without already computed subjects
# already_proc = [2, 36]  # already processed subjects
# subjects = np.setdiff1d(subjects, already_proc)

# < o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >><< o >>


def write_search_bash_files(subs, filetype, condition,
                            task_request=None, component_mode=1, eqcompmat=None,
                            seed=True,  repet_scalar=30, s_fold=10, sba=True,
                            batch_size=9, successive_mode=1, rand_batch=True, plot=True,
                            successive_default=3, del_log_folders=True, summaries=False,
                            n_combinations=None, n_subbash=4):
    """
    :param subs: subject list
    :param filetype: 'SSD' or 'SPOC'
    :param condition: 'mov' or 'nomov'
    :param task_request: '(r)egression' or '(c)lassification'
    :param component_mode: mode 1: only 'one-up'; mode 2: one-up or random choice of components
    :param eqcompmat: number of columns in input matrix. Gets filled with zero-vectors if not enough data
    :param seed: regarding randomization of folds, batches etc.
    :param repet_scalar: how many times it runs through whole set (can be also fraction)
    :param s_fold: number (s) of folds
    :param sba: True:= SBA, False:= SA
    :param batch_size: Batch size
    :param successive_mode: 1 or 2 (see load_data.py in next_batch())
    :param rand_batch: Should remain True
    :param plot: Whether to plot results after processing
    :param successive_default: How many of random batches shall remain in successive order. That is, the
    time-slices (1-sec each) that are kept in succession. Representing subjective experience, this could
    be 2-3 sec in order to capture responses to the stimulus environment.
    :param del_log_folders: Whether to delete log files and checkpoints after processing and plotting
    :param summaries: Whether verbose summaries (get deleted if del_log_folders==True)
    :param n_combinations: Number of random combinations in hyperparameter search
    :param n_subbash: Define number of sub-bashfiles (for distributed processing)
    :return:
    """

    # Adjust input variable
    if not type(subs) is int:
        subs = list(subs)
    else:
        subs = [subs]

    filetype = filetype.upper()  # filetype (alternatively: np.random.choice(a=['SSD', 'SPOC']))
    assert filetype in ['SSD', 'SPOC'], "filetype must be either 'SSD' or 'SPOC'"
    cond = condition.lower()
    assert cond in ['mov', 'nomov'], "condition must be either 'mov' or 'nomov'"
    assert component_mode in [1, 2], "component_mode must be either 1 or 2 (int)"
    assert isinstance(n_subbash, int), "n_subbash must be integer"

    if del_log_folders and summaries:
        cprint("Note: Verbose summaries are redundant since they get deleted after processing.", "y")

    # Request
    if n_combinations is None:
        n_combinations = int(cinput(
            "How many random combinations of hyperparameters to test (given value will be multpied with "
            "n_subjects)): ", "b"))

    tasks = ["regression", "classification"]
    if task_request is None:
        task_request = cinput(
            "For which task is the random search bash? ['r' for'regression', 'c' for 'classification']: ",
            "b")
    assert task_request.lower() in tasks[0] or task_request.lower() in tasks[1], \
        "Task input must be eitehr 'r' or 'c'"
    task = tasks[0] if task_request.lower() in tasks[0] else tasks[1]

    shuffle = True if task == "classification" else False
    successive = 1 if task == "classification" else successive_default

    if eqcompmat is None:
        eqcompmat = ask_true_false(question="Shall the model input matrix always be the same in size?")
        if eqcompmat:
            eqcompmat = int(cinput("What should be the number (int) of columns (i.e. components)?", "b"))
        else:
            eqcompmat = 0

    else:  # argument input for eqcompmat is integer
        assert isinstance(eqcompmat, int), "eqcompmat must be int"

    # Create bashfile if not there already:
    bash_file_name = p2_bash + f"bashfile_randomsearch_{'BiCl' if 'c' in task else 'Reg'}.sh"
    sub_bash_file_names = []
    subbash_suffix = ["_local.sh"] + [f"_{subba}.sh" for subba in range(1, n_subbash)]

    for sub_bash in subbash_suffix:
        sub_bash_file_name = "." + bash_file_name.split(".")[1] + sub_bash
        sub_bash_file_names.append(sub_bash_file_name)

    if not os.path.exists(bash_file_name):
        with open(bash_file_name, "w") as bashfile:  # 'a' for append
            bashfile.write("#!/usr/bin/env bash\n\n" + f"# Random Search Bashfile: {task}")
        for subash_fname in sub_bash_file_names:
            with open(subash_fname, "w") as bashfile:  # 'a' for append
                bashfile.write("#!/usr/bin/env bash\n\n"+"# Random Search Bashfile_{}: {}".format(
                    subash_fname.split("_")[-1].split(".")[0], task))

    # # Randomly Draw
    combi_count = 0
    for combi in range(n_combinations):

        # lstm_size
        n_lstm_layers = np.random.choice([1, 2])  # either 1 or 2 layers
        layer_size = [10, 15, 20, 25, 30, 40, 50, 65, 80, 100]  # possible layer sizes

        if n_lstm_layers == 1:
            lstm_size = np.random.choice(layer_size)
        else:  # n_lstm_layers == 2
            lstm_l1 = np.random.choice(layer_size)
            while True:  # size of second layer should be smaller or equal to size of first layer
                lstm_l2 = np.random.choice(layer_size)
                if lstm_l2 <= lstm_l1:
                    break
            lstm_size = "{},{}".format(lstm_l1, lstm_l2)

        # fc_n_hidden
        n_fc_layers = np.random.choice(range(n_lstm_layers))  # n_fc_layers <= n_lstm_layers
        # note: if n_fc_layers == len(fc_n_hidden) == 0, there is 1 fc-lay attached to lstm,
        # so 1 n_fc_layers == 2 fc layers

        if n_fc_layers == 0:
            fc_n_hidden = 0
        else:
            while True:
                fc_n_hidden = np.random.choice(layer_size)
                if n_lstm_layers == 1:
                    if fc_n_hidden <= lstm_size:
                        break
                else:  # n_lstm_layers == 2
                    if fc_n_hidden <= int(lstm_size.split(",")[1]):
                        break

        # learning_rate
        # learning_rate = np.random.choice(a=['1e-1', '1e-2', '1e-3', '5e-4'])
        learning_rate = np.random.choice(a=['1e-2', '1e-3', '5e-4'])

        # weight_reg
        weight_reg = np.random.choice(a=['l1', 'l2'])

        # weight_reg_strength
        weight_reg_strength = np.random.choice(a=[0.00001, 0.18, 0.36, 0.72, 1.44])  # .00001 == no regul.

        # activation_fct
        activation_fct = np.random.choice(a=['elu', 'relu'])

        # hilbert_power
        hilbert_power = np.random.choice(a=[True, False])

        # band_pass
        if filetype == "SPOC":
            band_pass = True  # there is no non-band-pass SPOC data (yet).
        else:  # filetype == "SSD"
            band_pass = np.random.choice(a=[True, False])

        # hrcomp
        hrcomp = np.random.choice(a=[True, False])

        # component
        if component_mode == 1:
            component_modes = "one_up"
        else:  # component_mode == 2
            component_modes = np.random.choice(a=["random_set", "one_up"])

        # From here on it is subject-dependent
        ncomp = [get_num_components(sub, cond, filetype) for sub in subs]  # TODO SPOC not there yet
        max_n_comp = max(ncomp)
        sub_dep = False  # init

        # Randomly choice number of feed-components
        while True:
            choose_n_comp = np.random.randint(1, max_n_comp+1)  # x
            if choose_n_comp <= 10:  # don't feed more than 10 components
                break

        # TODO adapt to selected components, per subjects !
        if component_modes == "one_up":
            # Choose from component 1 to n_choose (see: SPOC(comp_order) & SSD(alpha-hypotheses)):
            component = np.arange(start=1, stop=choose_n_comp + 1)  # range [1, n_choose]

        else:  # component_modes == "random_set"
            # Choose x random components, where x == choose_n_comp
            component = np.sort(np.random.choice(a=range(1, max_n_comp + 1), size=choose_n_comp,
                                                 replace=False))

        # Does this need to be adapted per subject?
        if not all([choose_n_comp <= maxcomp for maxcomp in ncomp]):
            sub_dep = True

        # eqcompmat
        if eqcompmat != 0:
            eqcompmat = max_n_comp if max_n_comp > eqcompmat else eqcompmat
            if eqcompmat > 10:
                cprint(f"eqcompmat {eqcompmat} is too big. eqcompmat is set to 10 (max) instead.", "y")
            eqcompmat = 10

        # Prepare to write line in bash file per subject
        for sidx, sub in enumerate(subs):

            sub_component = component

            if component_modes != "best":
                # Shorten component list for subject, if necessary
                if sub_dep:
                    # In case list of given components is too long for specific subject
                    if len(sub_component) > ncomp[sidx]:
                        # Shorten list, which is equal to taking all possible components of this subject
                        sub_component = np.arange(start=1, stop=ncomp[sidx]+1)

                    # In case the given 'highest' compoments(s) is/are beyond the component-scope of subj.
                    while max(sub_component) > len(sub_component):
                        # Find random component within the component-scope ...
                        while True:
                            repl_comp = np.random.choice(a=range(1, len(sub_component) + 1), size=1,
                                                         replace=False)[0]
                            # ... which is not in the given list of components yet ...
                            if repl_comp not in sub_component:
                                # ... and replace highest comp with it
                                sub_component[np.where(sub_component == max(sub_component))] = repl_comp
                                break

                sub_component = ','.join([str(i) for i in sub_component])

            # path_specificities
            path_specificities = f"{'BiCl_' if 'c' in task else 'Reg_'}RndHPS_" \
                f"lstm-{'-'.join(str(lstm_size).split(','))}_" \
                f"fc-{'-'.join(str(fc_n_hidden).split(','))}_" \
                f"lr-{learning_rate}_wreg-{weight_reg}-{weight_reg_strength:.2f}_" \
                f"actfunc-{activation_fct}_ftype-{filetype}_hilb-{'T' if hilbert_power else 'F'}_" \
                f"bpass-{'T' if band_pass else 'F'}_comp-{'-'.join(str(sub_component).split(','))}_" \
                f"hrcomp-{'T' if hrcomp else 'F'}_fixncol-{eqcompmat}/"

            # Write line for bashfile
            bash_line = f"python3 NeVRo.py --subject {sub} --condition {cond} --seed {seed} " \
                f"--task {task} --shuffle {shuffle} --repet_scalar {repet_scalar} --s_fold {s_fold} " \
                f"--batch_size {batch_size} --successive {successive} " \
                f"--successive_mode {successive_mode} --rand_batch {rand_batch} --plot {plot} " \
                f"--dellog {del_log_folders} --lstm_size {lstm_size} --fc_n_hidden {fc_n_hidden} " \
                f"--learning_rate {learning_rate} --weight_reg {weight_reg} " \
                f"--weight_reg_strength {weight_reg_strength} --activation_fct {activation_fct} " \
                f"--filetype {filetype} --hilbert_power {hilbert_power} --band_pass {band_pass} " \
                f"--component {sub_component} --hrcomp {hrcomp} --eqcompmat {eqcompmat} " \
                f"--summaries {summaries} --path_specificities {path_specificities}"

            # Write in bashfile
            if not os.path.exists("./processed/"):
                os.mkdir("./processed/")

            with open(bash_file_name, "a") as bashfile:  # 'a' for append
                bashfile.write("\n"+bash_line)

            # and in subbashfile
            sub_bash_file_name = sub_bash_file_names[combi_count]

            with open(sub_bash_file_name, "a") as sub_bashfile:  # 'a' for append
                sub_bashfile.write("\n"+bash_line)

            # Fill in Random_Search_Table.csv
            table_name = "./processed/Random_Search_Table_{}.csv".format('BiCl' if "c" in task else "Reg")

            if not os.path.exists(table_name):
                rs_table = np.array(['round', 'subject', 'cond', 'seed', 'task',
                                     'shuffle', 'repet_scalar', 's_fold', 'batch_size',
                                     'successive', 'successive_mode', 'rand_batch', 'plot',
                                     'lstm_size', 'fc_n_hidden', 'learning_rate',
                                     'weight_reg', 'weight_reg_strength',
                                     'activation_fct', 'filetype', 'hilbert_power', 'band_pass',
                                     'component', 'hrcomp', 'fixncol', 'summaries',
                                     'path_specificities',
                                     'mean_val_acc', 'zeroline_acc', 'mean_class_val_acc'],
                                    dtype='<U120')

                rs_table = np.reshape(rs_table, newshape=(-1, rs_table.shape[0]))
                # Could write del_log_folders in table

            else:
                rs_table = np.genfromtxt(table_name, delimiter=";", dtype=str)

            rnd = int(rs_table[-1, 0]) + 1 if rs_table[-1, 0].isnumeric() else 0

            exp_data = [rnd, sub, cond, seed, task,
                        shuffle, repet_scalar, s_fold, batch_size,
                        successive, successive_mode, rand_batch, plot,
                        lstm_size, fc_n_hidden, learning_rate,
                        weight_reg, weight_reg_strength,
                        activation_fct, filetype, hilbert_power, band_pass,
                        sub_component, hrcomp, eqcompmat, summaries,
                        path_specificities]

            fill_vec = np.repeat(a="nan", repeats=rs_table.shape[1])
            fill_vec = fill_vec.reshape((-1, len(fill_vec)))
            rs_table = np.concatenate((rs_table, fill_vec), axis=0).astype("<U125")
            rs_table[-1, 0:len(exp_data)] = exp_data

            np.savetxt(fname=table_name, X=rs_table, delimiter=";", fmt="%s")

            # Set Counter
            combi_count = combi_count+1 if combi_count < n_subbash-1 else 0

    print("\nBashfiles and table completed.")


# # Regression
# # Broad random search. Half (20/40) with fix sized input matrix (fixncomp=7)
# write_search_bash_files(subs=subsubjects, filetype="SSD", condition="nomov",
#                         task_request="r", component_mode=1, eqcompmat=7, n_combinations=20,
#                         seed=True, repet_scalar=30,
#                         s_fold=10, sba=True, batch_size=9, successive_mode=1, rand_batch=True,
#                         plot=True, successive_default=3, del_log_folders=True, summaries=False)
#
# write_search_bash_files(subs=subsubjects, filetype="SSD", condition="nomov",
#                         task_request="r", component_mode=1, eqcompmat=0, n_combinations=20,
#                         seed=True, repet_scalar=30,
#                         s_fold=10, sba=True, batch_size=9, successive_mode=1, rand_batch=True,
#                         plot=True, successive_default=3, del_log_folders=True, summaries=False)


# # Binary classification
# write_search_bash_files(subs=subsubjects, filetype="SSD", condition="nomov",
#                         task_request="c", component_mode=1, eqcompmat=7, n_combinations=4,
#                         seed=True, repet_scalar=30,
#                         s_fold=10, sba=True, batch_size=9, successive_mode=1, rand_batch=True,
#                         plot=True, successive_default=3, del_log_folders=True, summaries=False)
#
# write_search_bash_files(subs=subsubjects, filetype="SSD", condition="nomov",
#                         task_request="c", component_mode=1, eqcompmat=0, n_combinations=4,
#                         seed=True, repet_scalar=30,
#                         s_fold=10, sba=True, batch_size=9, successive_mode=1, rand_batch=True,
#                         plot=True, successive_default=3, del_log_folders=True, summaries=False)


# TODO continue here
def write_bash_from_table(subs, table_path):

    # # Following need to be set manually (Default)
    del_log_folders = True

    wd_tables = "./processed/Random Search Tables/"
    table_path = wd_tables + table_path
    # table_path = wd_tables \
    #              + "unique_Best_2_HPsets_over_10_Subjects_mean_acc_0.660_Random_Search_Table_BiCl.csv"

    if not isinstance(subs, list) and not isinstance(subs, np.ndarray):
        subs = [subs]

    num_sub = len(subs)

    assert os.path.exists(table_path), "Given table path does not exist"
    hp_table = np.genfromtxt(table_path, delimiter=";", dtype=str)

    # Create new HP-table
    n_combis = hp_table[1:].shape[0]
    rounds = np.arange(n_combis*num_sub)
    rounds = np.reshape(rounds, newshape=(len(rounds), 1))
    subs = np.tile(subs, n_combis)
    subs = np.reshape(subs, newshape=(len(subs), 1))
    lside_table = np.concatenate((rounds, subs), 1)
    lside_header = np.reshape(np.array(['round', 'subject'], dtype='<U125'), newshape=(1, 2))
    lside_table = np.concatenate((lside_header, lside_table))
    rside_header = np.reshape(np.array(['mean_val_acc', 'zeroline_acc', 'mean_class_val_acc'],
                                       dtype='<U125'), (1, 3))
    rside_table = np.reshape(np.repeat(np.repeat(a="nan", repeats=n_combis*num_sub), 3), newshape=(-1, 3))
    rside_table = np.concatenate((rside_header, rside_table))
    mid_table = np.repeat(hp_table[1:, :], num_sub, axis=0)
    mid_header = np.reshape(hp_table[0, :], newshape=(1, -1))
    mid_table = np.concatenate((mid_header, mid_table))

    new_hp_table = np.concatenate((np.concatenate((lside_table, mid_table), 1), rside_table), 1)

    # Save new HP-table
    new_table_name = "./processed/" + "Ran" + table_path.split("_Ran")[-1]
    np.savetxt(fname=new_table_name, X=new_hp_table, delimiter=";", fmt="%s")

    # Create bashfile if not there already:
    bash_filename = "bashfile_specific_search_{}.sh".format(table_path.split("_")[-1].split(".")[0])
    if not os.path.exists(bash_filename):
        with open(bash_filename, "w") as bash_file:  # 'a' for append
            bash_file.write("#!/usr/bin/env bash\n\n" + "# Specific Search Bashfile:")

        for subbash in ["_local.sh", "_1.sh", "_2.sh", "_3.sh"]:
            subbash_filename = bash_filename.split(".")[0] + subbash
            with open(subbash_filename, "w") as bash_file:  # 'a' for append
                bash_file.write(
                    "#!/usr/bin/env bash\n\n" + "# Specific Search Bashfile{}:".format(
                        subbash.split(".")[0]))

    # Write according bashfiles
    combi_count = 0
    for line in new_hp_table[1:, 1:-3]:

        subject, cond, seed, task, shuffle, \
            repet_scalar, s_fold, batch_size, \
            successive, successive_mode, rand_batch, \
            plot, \
            lstm_size, fc_n_hidden, learning_rate, \
            weight_reg, weight_reg_strength,\
            activation_fct, \
            filetype, hilbert_power, band_pass, \
            component, hrcomp, eqcompmat, summaries, \
            path_specificities = line

        # Write line for bashfile (Important: [Space] after each entry)

        bash_line = "python3 NeVRo.py " \
                    "--subject {} --condition {} --seed {} --task {} --shuffle {} " \
                    "--repet_scalar {} --s_fold {} --batch_size {} " \
                    "--successive {} --successive_mode {} --rand_batch {} " \
                    "--plot {} --dellog {} " \
                    "--lstm_size {} --fc_n_hidden {} --learning_rate {} " \
                    "--weight_reg {} --weight_reg_strength {} " \
                    "--activation_fct {} " \
                    "--filetype {} --hilbert_power {} --band_pass {} " \
                    "--component {} --hrcomp {} --eqcompmat {} --summaries {} " \
                    "--path_specificities {}".format(subject, cond, seed, task, shuffle,
                                                     repet_scalar, s_fold, batch_size,
                                                     successive, successive_mode, rand_batch,
                                                     plot, del_log_folders,
                                                     lstm_size, fc_n_hidden, learning_rate,
                                                     weight_reg, weight_reg_strength,
                                                     activation_fct,
                                                     filetype, hilbert_power, band_pass,
                                                     component, hrcomp, eqcompmat, summaries,
                                                     path_specificities)

        # Write in bashfile
        with open(bash_filename, "a") as bashfile:  # 'a' for append
            bashfile.write("\n" + bash_line)

        # and in subbashfile
        subbash = ["_local.sh", "_1.sh", "_2.sh", "_3.sh"][combi_count]
        sub_bash_file_name = bash_filename.split(".")[0] + subbash
        with open(sub_bash_file_name, "a") as subbashfile:  # 'a' for append
            subbashfile.write("\n" + bash_line)

        # Set Counter
        combi_count = combi_count + 1 if combi_count < 3 else 0

    print("\nBashfiles and Table completed.")

# write_bash_from_table(
#     subs=subjects,
#     table_path='unique_Best_2_HPsets_over_10_Subjects_mean_acc_0.660_Random_Search_Table_BiCl.csv')
# write_bash_from_table(
#     subs=subjects,
#     table_path='unique_Best_2_HPsets_over_10_Subjects_mean_acc_0.046_Random_Search_Table_Reg.csv')


def update_bashfiles(task, subject=None, path_specs=None, all_runs=False):

    assert "cl" in task.lower() or "reg" in task.lower(), \
        "task must be either 'regression' or 'classification'"

    # Load Random_Search_Table
    table_name = "./processed/Random_Search_Table_{}.csv".format('BiCl' if "c" in task.lower() else "Reg")
    if os.path.exists(table_name):
        rs_table = np.genfromtxt(table_name, delimiter=";", dtype=str)
        idx_sub = np.where(rs_table[0, :] == 'subject')[0][0]  # find column "subject"
        idx_pspec = np.where(rs_table[0, :] == 'path_specificities')[0][0]  # column "path_specificities"

        if not all_runs:
            subject = int(subject)
            # Find entry which needs to be updated
            idx_sub = np.where(rs_table[:, idx_sub] == str(subject))[0]  # rows with respective subject
            idx_pspec = np.where(rs_table[:, idx_pspec] == path_specs)[0]  # find respective path_specs
            idx_check = list(set(idx_sub).intersection(idx_pspec))  # find index of case at hand

            # If there is an entry, the run was successful, update bashfile(s)
            if not np.all(rs_table[idx_check, -3:] == 'nan'):

                # Run through all bashfiles and comment out those lines that were successfully executed
                for bfile in os.listdir("./bashfiles/"):
                    if bfile.split(".")[-1] == 'sh':  # check whether bash file
                        for line in fileinput.input("./bashfiles/" + bfile, inplace=True):
                            if path_specs in line and str(subject) in line and "#" not in line:
                                # Note: This doesn't print in console, but overwrites in file
                                sys.stdout.write('# {}'.format(line))
                                # sys.stdout.write() instead of print() avoids new lines
                            else:
                                sys.stdout.write(line)

        else:  # check for all runs

            # Run through table and find successfully executed entries
            for idx, rs_line in enumerate(rs_table[1:, -3:]):
                if not np.all(rs_line == 'nan'):
                    subject = rs_table[1+idx, idx_sub]
                    path_specs = rs_table[1+idx, idx_pspec]

                    for bfile in os.listdir("./bashfiles/"):
                        if bfile.split(".")[-1] == 'sh':  # check whether bash file
                            for line in fileinput.input("./bashfiles/" + bfile, inplace=True):
                                if path_specs in line and subject in line and "#" not in line:
                                    sys.stdout.write('# {}'.format(line))
                                else:
                                    sys.stdout.write(line)

    else:
        cprint("There is no corresponding table: '{}'".format(table_name), "r")
