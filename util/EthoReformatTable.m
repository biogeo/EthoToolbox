function [table, fields] = EthoReformatTable(table, varargin)

% Valid table formats:
% struct:
%   The table is represented a struct such that table.(field{i})(j) is the j'th
%   row of the i'th column.
% columns:
%   The table is represented as a cell array such that table{i}(j) is the j'th
%   row of the i'th column.
% cellarray:
%   The table is represented as a cell array such that table{j,i} is the j'th
%   row of the i'th column.

pars = etho_simple_argparser({
    'TableFormat', 'cellarray';
    'FormatHint', '';
    'FieldNames', {};
    }, varargin);

allFormats = {'struct', 'columns', 'cellarray'};
curFormat = lower(pars.FormatHint);
newFormat = lower(pars.TableFormat);
fields = cellstr(pars.FieldNames);

if ~ismember(curFormat, allFormats)
    % Autodetermine table format
    if isstruct(table) && isscalar(table)
        curFormat = 'struct';
    elseif iscell(table) && isvector(table)
        curFormat = 'columns';
    elseif iscell(table) && ismatrix(table)
        curFormat = 'cellarray';
    else
        error('Etho:badTableFormat', 'Unknown table format');
    end
end
[~, curFormatI] = ismember(curFormat, allFormats);
[isGood, newFormatI] = ismember(newFormat, allFormats);

if ~isGood
    error('Etho:badTableFormat', 'Unknown table format');
end

% Select the conversion function from the matrix below.
conversionTable = {
    @no_change,             @struct_to_columns,      @struct_to_cellarray;
    @columns_to_struct,     @no_change,              @columns_to_cellarray;
    @cellarray_to_struct,   @cellarray_to_columns,   @no_change;
    };
[table, fields] = conversionTable{curFormatI, newFormatI}(table, fields);


function [table, fields] = no_change(table, fields)
% PASS

function [table, fields] = struct_to_columns(table, fields)
if isempty(fields)
    fields = fieldnames(table);
end
table = struct2cell(table);

function [table, fields] = columns_to_cellarray(table, fields)
for i=1:numel(table)
    if ~iscell(table{i})
        table{i} = num2cell(table{i});
    end
end
table = horzcat(table{:});

function [table, fields] = struct_to_cellarray(table, fields)
[table, fields] = struct_to_columns(table, fields);
[table, fields] = columns_to_cellarray(table, fields);

function [table, fields] = cellarray_to_columns(table, fields)
[nrow, ncol] = size(table);
table = mat2cell(table, nrow, ones(1,ncol));
for i=1:ncol
    if all(cellfun(@(t)isnumeric(t)||islogical(t), table{i}))
        table{i} = vertcat(table{i}{:});
    end
end

function [table, fields] = columns_to_struct(table, fields)
if isempty(fields)
    ncol = numel(table);
    fields = strcat('var', strsplit(num2str(1:ncol)));
end
table = cell2struct(table, fields, 2);

function [table, fields] = cellarray_to_struct(table, fields)
[table, fields] = cellarray_to_columns(table, fields);
[table, fields] = columns_to_struct(table, fields);
