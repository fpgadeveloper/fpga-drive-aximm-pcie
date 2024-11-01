# Requirements

In order to test this design on hardware, you will need the following:

* Vivado 2024.1
* Vitis 2024.1
* PetaLinux Tools 2024.1
* 1x [FPGA Drive FMC Gen4] or [M.2 M-key Stack FMC]
* At least one M.2 NVMe PCIe Solid State Drive (see [supported SSDs](supported_ssds))
* One of the supported carrier boards listed below

## List of supported boards

{% set unique_boards = {} %}
{% for design in data.designs %}
	{% if design.publish %}
	    {% if design.board not in unique_boards %}
	        {% set _ = unique_boards.update({design.board: {"group": design.group, "link": design.link, "connectors": []}}) %}
	    {% endif %}
	    {% if design.connector not in unique_boards[design.board]["connectors"] %}
	    	{% set _ = unique_boards[design.board]["connectors"].append(design.connector) %}
	    {% endif %}
	{% endif %}
{% endfor %}

{% for group in data.groups %}
    {% set boards_in_group = [] %}
    {% for name, board in unique_boards.items() %}
        {% if board.group == group.label %}
            {% set _ = boards_in_group.append(board) %}
        {% endif %}
    {% endfor %}

    {% if boards_in_group | length > 0 %}
### {{ group.name }} boards

| Carrier board        | Supported FMC connector(s)    |
|---------------------|--------------|
{% for name,board in unique_boards.items() %}{% if board.group == group.label %}| [{{ name }}]({{ board.link }}) | {% for connector in board.connectors %}{{ connector }} {% endfor %} |
{% endif %}{% endfor %}
{% endif %}
{% endfor %}

For list of the target designs showing the number of M.2 slots and PCIe lanes supported, refer to the build instructions.

[FPGA Drive FMC Gen4]: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/
[M.2 M-key Stack FMC]: https://www.fpgadrive.com/docs/m2-mkey-stack-fmc/overview/

