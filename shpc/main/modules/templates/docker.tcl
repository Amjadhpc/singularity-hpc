#%Module

#=====
# Created by singularity-hpc (https://github.com/singularityhub/singularity-hpc)
# ##
# {{ module.name }} on {{ creation_date }}
#=====

proc ModulesHelp { } {

    puts stderr "This module is a {{ command }} container wrapper for {{ module.name }} v{{ module.tag.name }}"
    {% if description %}puts stderr "{{ module.config.description }}"{% endif %}
    puts stderr ""
    puts stderr "Container:"
    puts stderr " - {{ module.container_path }}"
    puts stderr "Commands include:"
    puts stderr " - {|module_name|}-run:"
    puts stderr "       {{ command }} run -i{% if settings.enable_tty %}t{% endif %} -u `id -u`:`id -g` --rm {% if settings.environment_file %}--env-file  <wrapperDir>/{{ settings.environment_file }} {% endif %} {% if settings.bindpaths %}-v {{ settings.bindpaths }} {% endif %}{% if features.home %}-v {{ features.home }} {% endif %} -v . -w . <container> \"\$@\""
    puts stderr " - {|module_name|}-shell:"
    puts stderr "       {{ command }} run -i{% if settings.enable_tty %}t{% endif %} -u `id -u`:`id -g` --rm --entrypoint {{ shell }} {% if settings.environment_file %} --env-file <wrapperDir>/{{ settings.environment_file }} {% endif %} {% if settings.bindpaths %}-v {{ settings.bindpaths }} {% endif %}{% if features.home %}-v {{ features.home }} {% endif %} -v . -w . <container>"
    puts stderr " - {|module_name|}-exec:"
    puts stderr "       {{ command }} run -i{% if settings.enable_tty %}t{% endif %} -u `id -u`:`id -g` --rm --entrypoint \"\" {% if settings.environment_file %} --env-file  <wrapperDir>/{{ settings.environment_file }} {% endif %} {% if settings.bindpaths %}-v {{ settings.bindpaths }} {% endif %}{% if features.home %}-v {{ features.home }} {% endif %} -v . -w . <container> \"\$@\""
    puts stderr " - {|module_name|}-inspect:"
    puts stderr "       {{ command }} inspect <container>"
    puts stderr " - {|module_name|}-container:"
    puts stderr "       echo \"\$PODMAN_CONTAINER\""
    puts stderr ""
{% if aliases %}{% for alias in aliases %}    puts stderr " - {{ alias.name }}:"
    puts stderr "       {{ command }} run -i{% if settings.enable_tty %}t{% endif %} --rm -u `id -u`:`id -g` --entrypoint {{ alias.entrypoint | replace("$", "\$") }} {% if settings.environment_file %}--settings.environment_file  <wrapperDir>/{{ settings.environment_file }} {% endif %}{% if settings.bindpaths %}-v {{ settings.bindpaths }} {% endif %}{% if features.home %}-v {{ features.home }} {% endif %}{% if alias.docker_options %}{{ alias.docker_options | replace("$", "\$") }} {% endif %} -v . -w . <container> {{ alias.args | replace("$", "\$") }} \"\$@\""
{% endfor %}{% endif %}
    puts stderr ""
    puts stderr "For each of the above, you can export:"
    puts stderr ""
    puts stderr "        - PODMAN_OPTS: to define custom options for {{ command }}"
    puts stderr "        - PODMAN_COMMAND_OPTS: to define custom options for the command"
    puts stderr "        - PODMAN_CONTAINER: to define the container unique resource identifier"
}

# Environment - only set if not already defined
if { ![info exists ::env(PODMAN_OPTS)] } {
    setenv PODMAN_OPTS ""
}
if { ![info exists ::env(PODMAN_COMMAND_OPTS)] } {
    setenv PODMAN_COMMAND_OPTS ""
}

{% include "includes/load_view.tcl" %}

# Variables

set name        "{{ module.name }}"
set version     "{{ module.tag.name }}"
set description "$name - $version"
set containerPath "{{ module.container_path }}"
set workdir [pwd]
{% if description %}set notes       "{{ module.config.description }}"{% endif %}
{% if url %}set homepage    "{{ module.config.url }}"{% endif %}
set helpcommand "This module is a {{ docker }} container wrapper for {{ module.name }} v{{ module.tag.name }}. {% if description %}{{ module.config.description }}{% endif %}"
{% if labels %}{% for key, value in labels.items() %}set {{ key }} "{{ value }}"
{% endfor %}{% endif %}

# directory containing this modulefile, once symlinks resolved (dynamically defined)
set moduleDir   [file dirname [expr { [string equal [file type ${ModulesCurrentModulefile}] "link"] ? [file readlink ${ModulesCurrentModulefile}] : ${ModulesCurrentModulefile} }]]

# If we have wrapper base set, honor it, otherwise we use the moduleDir
{% if settings.wrapper_base %}set wrapperDir "{{ module.wrapper_dir }}"{% else %}set wrapperDir "${moduleDir}"{% endif %}

# conflict with modules with the same alias name
conflict {{ parsed_name.tool }}
{% if name != parsed_name.tool %}conflict {{ module.name }}{% endif %}
{% if aliases %}{% for alias in aliases %}{% if alias.name != parsed_name.tool %}conflict {{ alias.name }}{% endif %}
{% endfor %}{% endif %}

# service environment variable to access full SIF image path
setenv PODMAN_CONTAINER "${containerPath}"

# interactive shell to any container, plus exec for aliases
set shellCmd "{{ command }} \${PODMAN_OPTS} run \${PODMAN_COMMAND_OPTS} -u `id -u`:`id -g` --rm -i{% if settings.enable_tty %}t{% endif %} --entrypoint {{ shell }} {% if settings.environment_file %}--env-file ${wrapperDir}/{{ settings.environment_file }}{% endif %} {% if settings.bindpaths %}-v {{ settings.bindpaths }} {% endif %}{% if features.home %}-v {{ features.home }} {% endif %} -v $workdir -w $workdir ${containerPath}"

# execCmd needs entrypoint to be the executor
set execCmd "{{ command }} \${PODMAN_OPTS} run -i{% if settings.enable_tty %}t{% endif %} \${PODMAN_COMMAND_OPTS} -u `id -u`:`id -g` --rm {% if settings.environment_file %} --env-file ${wrapperDir}/{{ settings.environment_file }}{% endif %} {% if settings.bindpaths %}-v {{ settings.bindpaths }}{% endif %}{% if features.home %}-v {{ features.home }} {% endif %} -v $workdir -w $workdir"
set runCmd "{{ command }} \${PODMAN_OPTS} run -i{% if settings.enable_tty %}t{% endif %} \${PODMAN_COMMAND_OPTS} -u `id -u`:`id -g` --rm {% if settings.environment_file %}--env-file  ${wrapperDir}/{{ settings.environment_file }}{% endif %} {% if settings.bindpaths %}-v {{ settings.bindpaths }} {% endif %}{% if features.home %}-v {{ features.home }} {% endif %} -v $workdir -w $workdir ${containerPath}"
set inspectCmd "{{ command }} \${PODMAN_OPTS} inspect ${containerPath}"

# wrapper scripts? Add bin to path
{% if wrapper_scripts %}prepend-path PATH ${wrapperDir}/bin{% endif %}

# "aliases" to module commands
{% if aliases %}if { [ module-info shell ] eq {bash} } {
  if { [ module-info mode load ] } {
{% for alias in aliases %}{% if alias.name not in wrapper_scripts %}    puts stdout "function {{ alias.name }}() { ${execCmd} {% if alias.docker_options %} {{ alias.docker_options | replace("$", "\$") }} {% endif %} --entrypoint {{ alias.entrypoint | replace("$", "\$") }} ${containerPath} {{ alias.args | replace("$", "\$") }} \"\$@\"; }; export -f {{ alias.name }};"{% endif %}
{% endfor %}
  }
  if { [ module-info mode remove ] } {
{% for alias in aliases %}{% if alias.name not in wrapper_scripts %}    puts stdout "unset -f {{ alias.name }};"{% endif %}
{% endfor %}
  }
} else {
{% for alias in aliases %}{% if alias.name not in wrapper_scripts %}  set-alias {{ alias.name }} "${execCmd} {% if alias.docker_options %} {{ alias.docker_options | replace("$", "\$") }} {% endif %} --entrypoint {{ alias.entrypoint | replace("$", "\$") }} ${containerPath} {{ alias.args | replace("$", "\$") }}"{% endif %}
{% endfor %}
}{% endif %}

{% if wrapper_scripts %}{% else %}
set-alias {|module_name|}-container "echo ${containerPath}"

set-alias {|module_name|}-shell "${shellCmd}"

# A customizable exec function
if { [ module-info shell ] eq {bash} } {
  set-alias {|module_name|}-exec "${execCmd} --entrypoint \"\" ${containerPath} \"\$@\""
} else {
  set-alias {|module_name|}-exec "${execCmd} --entrypoint \"\" ${containerPath}"
}

# Always provide a container run
if { [ module-info shell ] eq {bash} } {
  set-alias {|module_name|}-run "${runCmd} \"\$@\""
} else {
  set-alias {|module_name|}-run "${runCmd}"
}

# Inspect runscript or deffile easily!
set-alias {|module_name|}-inspect "${inspectCmd} ${containerPath}"{% endif %}

#=====
# Module options
#=====
module-whatis "    Name: {{ module.name }}"
module-whatis "    Version: {{ module.tag.name }}"
{% if description %}module-whatis "    Description: ${description}"{% endif %}
{% if url %}module-whatis "    Url: {{ module.config.url }}"{% endif %}
{% if labels %}{% for key, value in labels.items() %}module-whatis "    {{ key }}: {{ value }}"
{% endfor %}{% endif %}
{% if settings.podman_module %}module load {{ settings.podman_module }}{% endif %}
