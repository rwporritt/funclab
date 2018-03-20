function fl_turn_on_main_gui(h,WaitGui)
%% fl_turn_on_main_gui(h)
%   h is the main gui data
%   First turns off new project windows and welcome info
%   Then turns on the main tables views
%
%  Created 05/06/2015. Rob Porritt

%% Turns off the welcome message
set(h.welcome1_t,'visible','off')
set(h.welcome2_t,'visible','off')
set(h.welcome3_t,'visible','off')
set(h.welcome4_t,'visible','off')

%% Turn off new project (if on - does nothing if already off)
set(h.new_title_t,'visible','off')
set(h.new_projdir_t,'visible','off')
set(h.new_projdir_e,'visible','off')
set(h.new_adddata_t,'visible','off')
for n = 1:10
    eval(['set(h.new_browse' sprintf('%02.0f',n) '_pb,''visible'',''off'')'])
    eval(['set(h.new_dataset' sprintf('%02.0f',n) '_e,''visible'',''off'')'])
end
set(h.new_start_pb,'visible','off')

%% Turn off the fetching interface if on
set(h.new_fetch_title_t,'visible','off')
set(h.new_fetch_projdir_t,'visible','off')
set(h.new_fetch_projdir_e,'visible','off')
set(h.new_fetch_start_pb,'visible','off')
set(h.new_fetch_get_map_coords_pb,'visible','off')
set(h.new_fetch_lat_max_e,'visible','off');
set(h.new_fetch_lat_min_e,'visible','off');
set(h.new_fetch_lon_max_e,'visible','off');
set(h.new_fetch_lon_min_e,'visible','off');
set(h.new_fetch_get_stations_pb,'visible','off');
set(h.new_fetch_station_panel,'visible','off');
set(h.new_fetch_events_panel,'Visible','off');
set(h.new_fetch_search_start_time_text,'Visible','off');
set(h.new_fetch_search_end_time_text,'Visible','off');
set(h.new_fetch_start_year_pu,'visible','off');
set(h.new_fetch_start_month_pu,'visible','off');
set(h.new_fetch_start_day_pu,'visible','off');
set(h.new_fetch_end_year_pu,'visible','off');
set(h.new_fetch_end_month_pu,'visible','off');
set(h.new_fetch_end_day_pu,'visible','off');
set(h.new_fetch_search_magnitude_text,'visible','off');
set(h.new_fetch_min_mag_pu,'visible','off');
set(h.new_fetch_max_mag_pu,'visible','off');
set(h.new_fetch_event_mag_divider_t,'Visible','off');
set(h.new_fetch_search_distance_text,'Visible','off');
set(h.new_fetch_max_dist_e,'Visible','off');
set(h.new_fetch_min_dist_e,'Visible','off');
set(h.new_fetch_event_distance_divider_t,'Visible','off');
set(h.new_fetch_find_events_pb,'Visible','off');
set(h.new_fetch_max_depth_e,'Visible','off');
set(h.new_fetch_min_depth_e,'Visible','off');
set(h.new_fetch_search_depth_text,'Visible','off');
set(h.new_fetch_event_depth_divider_t,'Visible','off');
set(h.new_fetch_search_depth_text,'visible','off');
set(h.new_fetch_traces_panel,'visible','off');
%set(h.new_fetch_traces_timing_text,'Visible','off');
%set(h.new_fetch_traces_seconds_before_edit,'Visible','off');
%set(h.new_fetch_traces_phase_popup,'Visible','off');
set(h.new_fetch_traces_start_phase_popup,'Visible','off');
set(h.new_fetch_traces_start_time_text,'Visible','off');
set(h.new_fetch_traces_prior_seconds_edit,'Visible','off');
set(h.new_fetch_traces_start_seconds_label,'Visible','off');
set(h.new_fetch_traces_start_before_or_after_popup,'Visible','off');
set(h.new_fetch_traces_end_phase_popup,'Visible','off');
set(h.new_fetch_traces_end_time_text,'Visible','off');
set(h.new_fetch_traces_after_seconds_edit,'Visible','off');
set(h.new_fetch_traces_end_seconds_label,'Visible','off');
set(h.new_fetch_traces_end_before_or_after_popup,'Visible','off');
set(h.new_fetch_traces_end_phase_popup,'Visible','off');
set(h.new_fetch_traces_sample_rate_text,'Visible','off');
set(h.new_fetch_traces_sample_rate_popup,'Visible','off');
set(h.new_fetch_traces_sample_rate_label,'Visible','off');
set(h.new_fetch_traces_debug_button,'Visible','off');
set(h.easterEggPanel,'Visible','off');
set(h.new_fetch_rfprocessing_params_panel,'Visible','off');
set(h.new_fetch_traces_response_text,'Visible','off');
set(h.new_fetch_traces_response_popup,'Visible','off');
set(h.new_fetch_rfprocessing_taper_popup,'Visible','off');
set(h.new_fetch_rfprocessing_taper_text,'Visible','off');
set(h.new_fetch_rfprocessing_high_pass_edit,'Visible','off');
set(h.new_fetch_rfprocessing_filter_high_pass_text,'Visible','off');
set(h.new_fetch_rfprocessing_low_pass_edit,'Visible','off');
set(h.new_fetch_rfprocessing_filter_low_pass_text,'Visible','off');
set(h.new_fetch_rfprocessing_filter_order_text,'Visible','off');
set(h.new_fetch_rfprocessing_order_popup,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_edit,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_edit,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_text,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_text,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_text,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_popup,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_text,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_popup,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_edit,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_text,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_text,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_text,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_text,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_edit,'Visible','off');
set(h.new_fetch_rfprocessing_primary_choice_text,'Visible','off');
set(h.new_fetch_rfprocessing_secondary_choice_text,'Visible','off');
set(h.new_fetch_rfprocessing_taper_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_high_pass_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_low_pass_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_order_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_popup,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_2_popup,'Visible','off');
set(h.encryptedInfoPanel,'Visible','off');
set(h.encrypted_button,'Visible','off');

%% Turn on the main windows
set(h.explorer_fm,'visible','on')
set(h.tablemenu_pu,'visible','on')
set(h.tablesinfo_t,'visible','on')
set(h.tables_ls,'visible','on')
set(h.records_t,'visible','on')
set(h.recordsinfo_t,'visible','on')
set(h.records_ls,'visible','on')
set(h.info_t,'visible','on')
set(h.info_ls,'visible','on')
set(h.new_m,'Enable','off')
set(h.new_fetch_m,'Enable','off')
set(h.load_m,'Enable','off')
set(h.add_m,'Enable','on')
set(h.param_m,'Enable','on')
set(h.log_m,'Enable','on')
set(h.close_m,'Enable','on')
set(h.manual_m,'Enable','on')
set(h.autoselect_m,'Enable','on')
set(h.autoall_m,'Enable','on')
set(h.im_te_m,'Enable','on')
set(h.tepref_m,'Enable','on')
set(h.recompute_rayp_m,'Enable','on')
set(h.seis_m,'Enable','on')
set(h.record_m,'Enable','on')
set(h.stacked_record_m,'Enable','on')
set(h.moveout_m,'Enable','on')
set(h.moveout_image_m,'Enable','on')
%set(h.origintime_image_m,'Enable','on')
set(h.baz_m,'Enable','on')
set(h.baz_image_m,'Enable','on')
set(h.datastats_m,'Enable','on')
set(h.stamap_m,'Enable','on')
set(h.evtmap_m,'Enable','on')
set(h.datadiagram_m,'Enable','on')
set(h.ex_stations_m,'Enable','on')
set(h.ex_events_m,'Enable','on')
set(h.ex_te_m,'Enable','on')
set(h.ex_rfs_m,'Enable','on')
set(h.PRF_to_depth_m,'Enable','on')
set(h.off_dead_m,'Enable','on')
set(h.create_new_subset_m,'Enable','on')
set(h.autoselect_rms_m,'Enable','on')
set(h.autoselect_rms_all_m,'Enable','on')
set(h.autoselect_vr_coh_m,'Enable','on')
set(h.autoselect_vr_coh_all_m,'Enable','on')
if isfield(h,'addons')
    addons = h.addons;
    for n = 1:length(addons)
        eval(['set(h.' addons{n} '_m,''Enable'',''on'')'])
    end
end
set(h.message_t,'visible','on')


RecordMetadataStrings = evalin('base','RecordMetadataStrings');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
Tablemenu = evalin('base','Tablemenu');
set(h.tablemenu_pu,'String',Tablemenu(:,1))
TableValue = 1;
set(h.tablemenu_pu,'Value',TableValue)
Tables = sort(unique(RecordMetadataStrings(:,2)));

SetManagementCell = cell(1,6);
SetManagementCell{1,1} = 1:size(RecordMetadataDoubles,1);
SetManagementCell{1,2} = RecordMetadataStrings;
SetManagementCell{1,3} = RecordMetadataDoubles;
SetManagementCell{1,4} = Tablemenu;
SetManagementCell{1,5} = 'Base';
SetManagementCell{1,6} = [0.6 0 0];
CurrentSubsetIndex = 1;

set(h.tables_ls,'String',Tables)
set(h.tablesinfo_t,'String',[Tablemenu{TableValue,5} num2str(length(Tables))])
set(h.records_t,'String',Tablemenu{TableValue,6})
set(h.message_t,'String','Message:')
ProjectDirectory = evalin('base','ProjectDirectory');
[~,~,~] = mkdir(fullfile(ProjectDirectory,'FIGURES'));
set(h.project_t,'string',ProjectDirectory)

close(WaitGui);



